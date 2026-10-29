package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import org.junit.Assert.*
import org.junit.Test
import org.json.JSONObject

class VentCommissioningTest {
    private val projectID="11111111-1111-4111-8111-111111111111"
    private val roomID="22222222-2222-4222-8222-222222222222"
    private val terminalA="33333333-3333-4333-8333-333333333333"
    private val terminalB="44444444-4444-4444-8444-444444444444"
    private val terminalC="55555555-5555-4555-8555-555555555555"
    private val visitID="66666666-6666-4666-8666-666666666666"
    private fun rejects(block:()->Unit) {try{block()}catch(_:Exception){return};fail("Expected invalid commissioning state to reject")}
    private fun book():VentCommissioningBook {
        var value=VentCommissioningRules.addProject(VentCommissioningBook(),projectID,"Wohnung Nord")
        value=VentCommissioningRules.putRoom(value,projectID,VentRoom(roomID,"Wohnzimmer"))
        value=VentCommissioningRules.putTerminal(value,projectID,VentTerminal(terminalA,roomID,"Zuluft1",VentSide.SUPPLY,100.0,90.0))
        value=VentCommissioningRules.putTerminal(value,projectID,VentTerminal(terminalB,roomID,"Zuluft2",VentSide.SUPPLY,50.0,55.0))
        return VentCommissioningRules.putTerminal(value,projectID,VentTerminal(terminalC,roomID,"Abluft",VentSide.EXTRACT,80.0,70.0))
    }
    private fun unmeasuredBook(omitField:Boolean=false):VentCommissioningBook {
        val root=JSONObject(VentCommissioningCodec.encode(book()))
        val row=root.getJSONArray("projects").getJSONObject(0).getJSONArray("terminals").getJSONObject(0)
        if(omitField)row.remove("measuredM3H")else row.put("measuredM3H",JSONObject.NULL)
        return VentCommissioningCodec.decode(root.toString())
    }
    @Test fun unmeasuredTerminalSuppressesCompleteTotalsButRecordedZeroRemainsAMeasurement() {
        val missing=unmeasuredBook().projects.single()
        val supply=VentCommissioningRules.totals(missing.terminals,VentSide.SUPPLY)
        assertEquals(150.0,supply.targetM3H,0.0)
        assertNull(supply.measuredM3H);assertNull(supply.deviationM3H);assertNull(supply.deviationPercent)
        assertNull(supply.measuredLitresPerSecond);assertNull(supply.measuredCFM)
        assertEquals(70.0,VentCommissioningRules.totals(missing.terminals,VentSide.EXTRACT).measuredM3H!!,0.0)
        val zero=VentCommissioningRules.totals(listOf(missing.terminals.first().copy(measuredM3H=0.0)),VentSide.SUPPLY)
        assertEquals(0.0,zero.measuredM3H!!,0.0);assertEquals(-100.0,zero.deviationPercent!!,0.0)
        assertNull(VentCommissioningRules.totals(emptyList(),VentSide.EXTRACT).measuredM3H)
    }
    @Test fun absentAndNullMeasurementsSurviveArchiveAndVisitsWithoutBecomingZero() {
        for(omit in listOf(false,true)) {
            var value=unmeasuredBook(omit)
            assertNull(value.projects.single().terminals.first().measuredM3H)
            value=VentCommissioningRules.recordVisit(value,projectID,visitID,"2026-10-29T10:00:00Z","Open measurement")
            value=VentCommissioningRules.putTerminal(value,projectID,value.projects.single().terminals.first().copy(measuredM3H=100.0))
            val restored=VentCommissioningCodec.decode(VentCommissioningCodec.encode(value))
            assertEquals(value,restored)
            assertNull(restored.projects.single().visits.single().terminals.first().measuredM3H)
            assertEquals(100.0,restored.projects.single().terminals.first().measuredM3H!!,0.0)
        }
    }
    @Test fun legacyNumericZeroMigratesInMemoryAndSurvivesTheNextExplicitSave() {
        val directory=Files.createTempDirectory("vent-legacy-").toFile()
        try {
            val current=book();val row=current.projects.single().terminals.first().copy(measuredM3H=0.0)
            val legacy=VentCommissioningRules.putTerminal(current,projectID,row)
            val json=JSONObject(VentCommissioningCodec.encode(legacy)).put("schema",1).toString()
            val file=File(directory,"vent-commissioning-v1.json");file.writeText(json)
            val raw=file.readBytes();val store=VentCommissioningFile(file);val loaded=store.load()
            assertArrayEquals(raw,file.readBytes());assertEquals(2,loaded.schema)
            assertEquals(0.0,loaded.projects.single().terminals.first().measuredM3H!!,0.0)
            val next=VentCommissioningRules.putRoom(loaded,projectID,VentRoom(roomID,"Renamed"))
            store.save(next,loaded.revision)
            assertEquals(2,JSONObject(file.readText()).getInt("schema"))
            assertEquals(0.0,store.load().projects.single().terminals.first().measuredM3H!!,0.0)
        } finally {directory.deleteRecursively()}
    }
    @Test fun reportsDistinguishUnmeasuredFromActualZeroAndMarkIncompleteSides() {
        val value=unmeasuredBook()
        val en=VentCommissioningRules.report(value,projectID,true)
        val de=VentCommissioningRules.report(value,projectID,false)
        assertTrue(en.contains("Unmeasured"));assertTrue(en.contains("Incomplete"))
        assertTrue(de.contains("Nicht gemessen"));assertTrue(de.contains("Unvollständig"))
        val zero=VentCommissioningRules.putTerminal(value,projectID,value.projects.single().terminals.first().copy(measuredM3H=0.0))
        val zeroReport=VentCommissioningRules.report(zero,projectID,true)
        assertFalse(zeroReport.contains("Unmeasured"));assertTrue(zeroReport.contains("0.00"))
    }
    @Test fun optionalMeasurementDoesNotPermitMalformedNumbersOrUnexpectedFields() {
        val root=JSONObject(VentCommissioningCodec.encode(book()))
        val row=root.getJSONArray("projects").getJSONObject(0).getJSONArray("terminals").getJSONObject(0)
        for(bad in listOf("garbage", "0", true, -1.0, 100001.0)) {
            row.put("measuredM3H",bad);rejects {VentCommissioningCodec.decode(root.toString())}
        }
        row.put("measuredM3H",JSONObject.NULL);row.put("foreign",true)
        rejects {VentCommissioningCodec.decode(root.toString())}
    }
    @Test fun supplyAndExtractHaveSeparateActualTotalsAndNoSilentNetting() {
        val project=book().projects.single()
        val supply=VentCommissioningRules.totals(project.terminals,VentSide.SUPPLY)
        val extract=VentCommissioningRules.totals(project.terminals,VentSide.EXTRACT)
        assertEquals(150.0,supply.targetM3H,0.0);assertEquals(145.0,supply.measuredM3H!!,0.0)
        assertEquals(-5.0,supply.deviationM3H!!,0.0);assertEquals(-5.0/150.0*100,supply.deviationPercent!!,1e-12)
        assertEquals(80.0,extract.targetM3H,0.0);assertEquals(70.0,extract.measuredM3H!!,0.0)
        assertEquals(145.0/3.6,supply.measuredLitresPerSecond!!,1e-12)
        assertEquals(145.0*.588577779,supply.measuredCFM!!,1e-12)
        val zero=VentCommissioningRules.totals(listOf(project.terminals.first().copy(targetM3H=0.0,measuredM3H=25.0)),VentSide.SUPPLY)
        assertNull(zero.deviationPercent);assertEquals(25.0,zero.deviationM3H!!,0.0)
    }
    @Test fun realRoomAndTerminalEditsDoNotRewriteSavedAdjustmentVisits() {
        var value=book();val original=value
        value=VentCommissioningRules.recordVisit(value,projectID,visitID,"2026-10-21T10:00:00Z","Vor Einstellung")
        val snapshot=value.projects.single().visits.single()
        value=VentCommissioningRules.putRoom(value,projectID,VentRoom(roomID,"Wohnraum umbenannt"))
        value=VentCommissioningRules.putTerminal(value,projectID,value.projects.single().terminals.first().copy(measuredM3H=100.0))
        value=VentCommissioningRules.removeTerminal(value,projectID,terminalB)
        val old=value.projects.single().visits.single()
        assertEquals(snapshot,old);assertEquals("Wohnzimmer",old.rooms.single().name)
        assertEquals(90.0,old.terminals.first().measuredM3H!!,0.0);assertEquals(3,old.terminals.size)
        assertEquals(0,original.projects.single().visits.size);assertEquals(90.0,original.projects.single().terminals.first().measuredM3H!!,0.0)
        value=VentCommissioningRules.recordVisit(value,projectID,"77777777-7777-4777-8777-777777777777","2026-10-22T10:00:00Z","Nach Einstellung")
        assertEquals(2,value.projects.single().visits.size);assertEquals(2,value.projects.single().visits.last().terminals.size)
        rejects {VentCommissioningRules.removeRoom(value,projectID,roomID)}
    }
    @Test fun foreignIDsInvalidNumbersDuplicateHistoryAndEmptyVisitsReject() {
        val value=book();val terminal=value.projects.single().terminals.first()
        rejects {VentCommissioningRules.putTerminal(value,projectID,terminal.copy(roomID="99999999-9999-4999-8999-999999999999"))}
        rejects {VentCommissioningRules.putTerminal(value,projectID,terminal.copy(targetM3H=-1.0))}
        rejects {VentCommissioningRules.putTerminal(value,projectID,terminal.copy(measuredM3H=Double.NaN))}
        rejects {VentCommissioningRules.putRoom(value,projectID,VentRoom(roomID," "))}
        val recorded=VentCommissioningRules.recordVisit(value,projectID,visitID,"2026-10-21T10:00:00Z","")
        rejects {VentCommissioningRules.recordVisit(recorded,projectID,visitID,"2026-10-22T10:00:00Z","")}
        rejects {VentCommissioningRules.recordVisit(value,projectID,visitID,"yesterday","")}
        val empty=VentCommissioningRules.addProject(VentCommissioningBook(),projectID,"Leer")
        rejects {VentCommissioningRules.recordVisit(empty,projectID,visitID,"2026-10-21T10:00:00Z","")}
    }
    @Test fun commissioningReportContainsTargetsMeasuredSidesHistoryAndExplicitMissingPercentage() {
        var value=book();value=VentCommissioningRules.putTerminal(value,projectID,value.projects.single().terminals.first().copy(targetM3H=0.0))
        value=VentCommissioningRules.recordVisit(value,projectID,visitID,"2026-10-21T10:00:00Z","Erster Abgleich")
        val de=VentCommissioningRules.report(value,projectID,false);val en=VentCommissioningRules.report(value,projectID,true)
        for(text in listOf(de,en)){assertTrue(text.contains("Wohnung Nord"));assertTrue(text.contains("Wohnzimmer"));assertTrue(text.contains("Zuluft1"));assertTrue(text.contains("Erster Abgleich"));assertTrue(text.contains("m³/h"));assertTrue(text.contains("2026-10-21T10:00:00Z"))}
        assertTrue(de.contains("Zuluft"));assertTrue(de.contains("Abluft"));assertTrue(de.contains("Soll"));assertTrue(de.contains("Ist"));assertTrue(de.contains("ohne Soll"))
        assertTrue(en.contains("Supply"));assertTrue(en.contains("Extract"));assertTrue(en.contains("Target"));assertTrue(en.contains("Measured"));assertTrue(en.contains("no target"))
    }
    @Test fun actualArchiveColdReloadStaleFailureAndExternalBadBytesRetainPriorData() {
        val directory=Files.createTempDirectory("vent-commissioning-").toFile()
        try {
            val file=File(directory,"vent-commissioning-v1.json");val store=VentCommissioningFile(file)
            val first=VentCommissioningRules.addProject(VentCommissioningBook(),projectID,"Kaltstart")
            store.save(first,0);assertEquals(first,VentCommissioningFile(file).load())
            val next=VentCommissioningRules.putRoom(first,projectID,VentRoom(roomID,"Raum"));val bytes=file.readBytes()
            val fail=VentCommissioningFile(file){_,_->throw java.io.IOException("synthetic")}
            rejects {fail.save(next,first.revision)};assertArrayEquals(bytes,file.readBytes())
            store.save(next,first.revision);store.save(next,first.revision);assertEquals(next,store.load())
            rejects {store.save(first,first.revision)}
            val json=VentCommissioningCodec.encode(next)
            assertEquals(next,VentCommissioningCodec.decode(json));rejects {VentCommissioningCodec.decode(json+" junk")}
            rejects {VentCommissioningCodec.encode(next.copy(projects=next.projects+next.projects.single()))}
            for(bad in listOf("{\"schema\":99}","broken",json+" trailing")) {file.writeText(bad);val raw=file.readBytes();rejects {store.load()};rejects {store.save(next,first.revision)};assertArrayEquals(raw,file.readBytes())}
        } finally {directory.deleteRecursively()}
    }
}
