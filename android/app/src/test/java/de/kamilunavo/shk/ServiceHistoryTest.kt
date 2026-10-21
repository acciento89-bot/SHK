package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test

class ServiceHistoryTest {
    private fun id(number:Int)=UUID(0,number.toLong()).toString()
    private fun rejects(block:()->Unit){try{block()}catch(_:Exception){return};fail("Expected invalid service history to reject")}
    private fun measurement()=ServiceMeasurements(55.0,45.0,1.5,1.9,8.0,3.0)
    private fun limits()=ServiceLimits(1.2,2.0)
    private fun template()=ServiceTemplate(id(2),"Jahreswartung",1,listOf(ServiceChecklistItem(id(3),"Dichtheit geprüft"),ServiceChecklistItem(id(4),"Filter geprüft")))
    private fun book():ServiceHistoryBook=ServiceHistoryRules.addTemplate(ServiceHistoryRules.addInstallation(ServiceHistoryBook(),ServiceInstallation(id(1),"Heizzentrale Nord")),template())
    private fun visit()=ServiceVisit(id(5),id(1),"2026-10-21T10:00:00Z",measurement(),limits(),template(),listOf(id(3)),"Messung vor Einstellung","2026-12-21")
    @Test fun preservesExistingMeasurementAndOwnLimitExpressionsWithoutSafetyApproval() {
        val value=ServiceHistoryRules.values(measurement(),limits())
        assertEquals(10.0,value.spreadK,0.0);assertEquals(.4,value.pressureRiseBar,1e-12)
        assertEquals(8*.0980665+.3,value.staticMinimumBar,1e-12)
        assertEquals(1.1,value.valveMarginBar,1e-12);assertEquals(0,value.warningCount)
        val abnormal=ServiceHistoryRules.values(measurement().copy(flowC=40.0,returnC=55.0,coldBar=.1,hotBar=3.0),limits())
        assertEquals(-15.0,abnormal.spreadK,0.0);assertEquals(5,abnormal.warningCount)
        rejects {ServiceHistoryRules.values(measurement().copy(coldBar=Double.NaN),limits())}
        rejects {ServiceHistoryRules.values(measurement(),ServiceLimits(2.0,1.0))}
    }
    @Test fun templateRevisionNeverRewritesPriorVisitChecklistMeasurementsOrLimits() {
        val original=ServiceHistoryRules.addVisit(book(),visit())
        val revised=ServiceHistoryRules.reviseTemplate(original,id(2),"Neue Jahreswartung",listOf(ServiceChecklistItem(id(3),"Neue Formulierung"),ServiceChecklistItem(id(6),"Ventil geprüft")))
        assertEquals(2,revised.templates.single().version)
        assertEquals(1,revised.visits.single().template.version)
        assertEquals("Dichtheit geprüft",revised.visits.single().template.items.first().label)
        assertEquals(limits(),revised.visits.single().limits);assertEquals(measurement(),revised.visits.single().measurements)
        assertEquals("Jahreswartung",original.templates.single().name)
        rejects {ServiceHistoryRules.addVisit(revised,visit().copy(id=id(7)))}
        val next=visit().copy(id=id(7),recordedAt="2026-11-21T10:00:00Z",template=revised.templates.single(),checked=listOf(id(6)),nextServiceDate="2027-11-21")
        val saved=ServiceHistoryRules.addVisit(revised,next)
        assertEquals(2,saved.visits.size);assertEquals("2027-11-21",ServiceHistoryRules.nextServices(saved).single().date)
    }
    @Test fun foreignInstallationUnknownChecksDuplicateVisitsAndBadDatesReject() {
        val original=book();val saved=ServiceHistoryRules.addVisit(original,visit())
        rejects {ServiceHistoryRules.addVisit(saved,visit())}
        rejects {ServiceHistoryRules.addVisit(original,visit().copy(installationID=id(99)))}
        rejects {ServiceHistoryRules.addVisit(original,visit().copy(checked=listOf(id(99))))}
        rejects {ServiceHistoryRules.addVisit(original,visit().copy(checked=listOf(id(3),id(3))))}
        rejects {ServiceHistoryRules.addVisit(original,visit().copy(recordedAt="yesterday"))}
        rejects {ServiceHistoryRules.addVisit(original,visit().copy(nextServiceDate="2026-02-30"))}
        assertTrue(ServiceHistoryRules.nextServices(original).isEmpty())
        assertEquals(0,original.visits.size)
    }
    @Test fun serviceReportContainsSnapshotVersionActualUserLimitsAndLocalNextDateInDEEN() {
        val value=ServiceHistoryRules.addVisit(book(),visit());val de=ServiceHistoryRules.report(value,id(1),false);val en=ServiceHistoryRules.report(value,id(1),true)
        for(text in listOf(de,en)){assertTrue(text.contains("Heizzentrale Nord"));assertTrue(text.contains("Jahreswartung"));assertTrue(text.contains("Dichtheit geprüft"));assertTrue(text.contains("Filter geprüft"));assertTrue(text.contains("2026-12-21"));assertTrue(text.contains("2026-10-21T10:00:00Z"));assertTrue(text.contains("bar"))}
        assertTrue(de.contains("Keine Sicherheitsfreigabe"));assertTrue(de.contains("Version"))
        assertTrue(en.contains("No safety approval"));assertTrue(en.contains("Version"));assertTrue(en.contains("local"))
    }
    @Test fun realVersionedArchiveSurvivesColdStartAndRetainsBadBytesOnSaveFailure() {
        val directory=Files.createTempDirectory("service-history-").toFile()
        try {
            val file=File(directory,"service-history.json");val store=ServiceHistoryFile(file)
            val first=ServiceHistoryRules.addInstallation(ServiceHistoryBook(),ServiceInstallation(id(1),"Kaltstart"));store.save(first,0);assertEquals(first,store.load())
            val next=ServiceHistoryRules.addTemplate(first,template());val bytes=file.readBytes()
            rejects {ServiceHistoryFile(file){_,_->throw java.io.IOException("synthetic")}.save(next,first.revision)};assertArrayEquals(bytes,file.readBytes())
            store.save(next,first.revision);store.save(next,first.revision);assertEquals(next,ServiceHistoryFile(file).load())
            val saved=ServiceHistoryRules.addVisit(book(),visit());val json=ServiceHistoryCodec.encode(saved)
            assertEquals(saved,ServiceHistoryCodec.decode(json));rejects {ServiceHistoryCodec.decode(json+" trailing")}
            rejects {ServiceHistoryCodec.encode(saved.copy(visits=saved.visits+saved.visits.single()))}
            for(bad in listOf("broken","{\"schema\":99}",json+" trailing")){file.writeText(bad);val raw=file.readBytes();rejects {store.load()};rejects {store.save(next,first.revision)};assertArrayEquals(raw,file.readBytes())}
        } finally {directory.deleteRecursively()}
    }
}
