package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import org.junit.Assert.*
import org.junit.Test

class KalteServiceTest {
    private val assetID="11111111-1111-4111-8111-111111111111"
    private val visitID="22222222-2222-4222-8222-222222222222"
    private val at="2026-10-21T10:00:00Z"
    private fun reading()=KalteReading(4.0,11.0,42.0,36.0,7.5,24.0,800.0,27.0,19.0)
    private fun book()=KalteServiceRules.addAsset(KalteServiceBook(),KalteAsset(assetID,"Wärmepumpe Nord"))
    private fun visit()=KalteVisit(visitID,assetID,at,reading(),reading().copy(suctionC=13.0,liquidC=35.0,airFlowM3H=1000.0),"Messgerät: eigene Sättigungstemperaturen")
    private fun rejects(block:()->Unit) {try {block()}catch(_:Exception){return};fail("Expected invalid state to reject")}

    @Test fun exactExistingFormulaAndSignedDiagnostics() {
        val values=KalteServiceRules.values(reading())
        assertEquals(7.0,values.superheatK,1e-12);assertEquals(6.0,values.subcoolingK,1e-12)
        assertEquals((24.0+1.01325)/(7.5+1.01325),values.compressorRatio,1e-12)
        assertEquals(800.0*8.0*0.000335,values.sensibleKW,1e-12)
        val signed=KalteServiceRules.values(reading().copy(suctionC=2.0,liquidC=44.0,dischargeGaugeBar=2.0))
        assertEquals(-2.0,signed.superheatK,1e-12);assertEquals(-2.0,signed.subcoolingK,1e-12)
        assertTrue(signed.compressorRatio in 0.0..1.0)
        val delta=KalteServiceRules.delta(reading(),visit().after)
        assertEquals(2.0,delta.superheatK,1e-12);assertEquals(1.0,delta.subcoolingK,1e-12)
        assertEquals(0.0,delta.compressorRatio,1e-12);assertEquals(200.0*8.0*.000335,delta.sensibleKW,1e-12)
    }
    @Test fun invalidNumericValuesCannotProduceSavedResults() {
        rejects {KalteServiceRules.values(reading().copy(suctionC=Double.NaN))}
        rejects {KalteServiceRules.values(reading().copy(liquidC=Double.POSITIVE_INFINITY))}
        rejects {KalteServiceRules.values(reading().copy(suctionGaugeBar=-1.01325))}
        rejects {KalteServiceRules.values(reading().copy(dischargeGaugeBar=-2.0))}
        rejects {KalteServiceRules.values(reading().copy(airFlowM3H=-1.0))}
        assertEquals(0.0,KalteServiceRules.values(reading().copy(airFlowM3H=0.0)).sensibleKW,0.0)
    }
    @Test fun namedAssetsAppendOnlyVisitsAndForeignIDs() {
        val original=book();val saved=KalteServiceRules.addVisit(original,visit())
        assertEquals(0,original.visits.size);assertEquals(1,saved.visits.size);assertEquals(original.revision+1,saved.revision)
        assertEquals(11.0,saved.visits.single().before.suctionC,0.0)
        rejects {KalteServiceRules.addVisit(saved,visit())}
        rejects {KalteServiceRules.addAsset(saved,KalteAsset(assetID,"Duplicate"))}
        rejects {KalteServiceRules.addAsset(saved,KalteAsset("bad","Unknown"))}
        rejects {KalteServiceRules.addAsset(saved,KalteAsset("33333333-3333-4333-8333-333333333333"," "))}
        rejects {KalteServiceRules.addVisit(original,visit().copy(assetID="33333333-3333-4333-8333-333333333333"))}
        rejects {KalteServiceRules.addVisit(original,visit().copy(recordedAt="tomorrow"))}
        rejects {KalteServiceRules.removeAsset(saved,assetID)}
        assertTrue(KalteServiceRules.removeAsset(original,assetID).assets.isEmpty())
    }
    @Test fun actualSavedReportContainsBeforeAfterAndAllAssumptionsInBothLanguages() {
        val saved=KalteServiceRules.addVisit(book(),visit())
        val de=KalteServiceRules.report(saved,assetID,false);val en=KalteServiceRules.report(saved,assetID,true)
        for(report in listOf(de,en)) {assertTrue(report.contains("Wärmepumpe Nord"));assertTrue(report.contains(at));assertTrue(report.contains("bar(g)"));assertTrue(report.contains("1.01325"));assertTrue(report.contains("kW"));assertTrue(report.contains("Messgerät"))}
        assertTrue(de.contains("Vorher"));assertTrue(de.contains("Nachher"));assertTrue(de.contains("Änderung"));assertTrue(de.contains("Sättigung"));assertTrue(de.contains("sensible"))
        assertTrue(en.contains("Before"));assertTrue(en.contains("After"));assertTrue(en.contains("Change"));assertTrue(en.contains("saturation"));assertTrue(en.contains("sensible"))
    }
    @Test fun strictCodecRejectsTrailingFutureDuplicateAndPreservesColdFile() {
        val saved=KalteServiceRules.addVisit(book(),visit());val json=KalteServiceCodec.encode(saved)
        assertEquals(saved,KalteServiceCodec.decode(json))
        rejects {KalteServiceCodec.decode(json+" trailing corruption")};rejects {KalteServiceCodec.decode("{\"schema\":99}")}
        rejects {KalteServiceCodec.encode(saved.copy(assets=saved.assets+saved.assets.first()))}
        rejects {KalteServiceCodec.encode(saved.copy(visits=saved.visits+saved.visits.first()))}
        val directory=Files.createTempDirectory("kalte-service-test-").toFile()
        try {
            val file=File(directory,"kalte-service-v1.json");val legacy=File(directory,"old-calculator-bytes");legacy.writeText("existing calculator untouched")
            val store=KalteServiceFile(file);assertEquals(KalteServiceBook(),store.load())
            val first=book();store.save(first,0);assertEquals(first,KalteServiceFile(file).load())
            val old=file.readBytes();val failed=KalteServiceFile(file) {_,_->throw java.io.IOException("synthetic failure")}
            rejects {failed.save(saved,first.revision)};assertArrayEquals(old,file.readBytes())
            store.save(saved,first.revision);store.save(saved,first.revision);assertEquals(saved,KalteServiceFile(file).load())
            rejects {store.save(first,first.revision)}
            assertEquals("existing calculator untouched",legacy.readText())
            for(bytes in listOf("damaged".toByteArray(),"{\"schema\":99}".toByteArray(),(json+" trailing").toByteArray(),ByteArray(2*1024*1024+1))) {
                file.writeBytes(bytes);rejects {store.load()};rejects {store.save(saved,first.revision)};assertArrayEquals(bytes,file.readBytes())
            }
        } finally {directory.deleteRecursively()}
    }
}
