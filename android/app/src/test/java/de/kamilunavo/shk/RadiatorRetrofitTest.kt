package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import kotlin.math.ln
import kotlin.math.pow
import org.junit.Assert.*
import org.junit.Test

class RadiatorRetrofitTest {
    private val projectID="11111111-1111-4111-8111-111111111111"
    private val roomID="22222222-2222-4222-8222-222222222222"
    private val scenarioID="33333333-3333-4333-8333-333333333333"
    private val currentID="44444444-4444-4444-8444-444444444444"
    private val proposedID="55555555-5555-4555-8555-555555555555"
    private fun rejects(block:()->Unit){try{block()}catch(_:Exception){return};fail("Expected invalid retrofit state to reject")}
    private fun emitter()=RadiatorEmitter(currentID,"Hersteller Typ22",2000.0,1.3,1)
    private fun scenario()=RadiatorScenario(scenarioID,"Normpunkt",75.0,65.0,20.0)
    private fun book():RadiatorRetrofitBook {
        var book=RadiatorRetrofitRules.addProject(RadiatorRetrofitBook(),projectID,"Altbau Nord")
        book=RadiatorRetrofitRules.putScenario(book,projectID,scenario())
        return RadiatorRetrofitRules.putRoom(book,projectID,RadiatorRoom(roomID,"Wohnzimmer",1500.0,listOf(emitter()),listOf(emitter().copy(id=proposedID,nominalW=2500.0))))
    }
    @Test fun exactOldArithmeticAndLogarithmicManufacturerPowerExpressions() {
        val standard=RadiatorRetrofitRules.values(emitter(),scenario());assertEquals(2000.0,standard.actualW,1e-9);assertEquals(50.0,standard.overtemperatureK,0.0);assertFalse(standard.logarithmic)
        val low=RadiatorRetrofitRules.values(emitter(),scenario().copy(supplyC=55.0,returnC=45.0))
        assertEquals(2000.0*(30.0/50.0).pow(1.3),low.actualW,1e-9)
        assertEquals(low.actualW/(1.163*10.0),low.flowLPH,1e-9)
        val log=RadiatorRetrofitRules.values(emitter(),scenario().copy(supplyC=45.0,returnC=25.0))
        val delta=20.0/ln(25.0/5.0);val reference=10.0/ln(55.0/45.0)
        assertTrue(log.logarithmic);assertEquals(delta,log.overtemperatureK,1e-12)
        assertEquals(2000.0*(delta/reference).pow(1.3),log.actualW,1e-9)
        assertEquals(4000.0,RadiatorRetrofitRules.values(emitter().copy(count=2),scenario()).actualW,1e-9)
        assertEquals(0.0,RadiatorRetrofitRules.values(emitter(),scenario().copy(returnC=75.0)).flowLPH,0.0)
    }
    @Test fun roomShortfallsAreSummedRatherThanCancelledByAnotherRoomSurplus() {
        var value=book();value=RadiatorRetrofitRules.putRoom(value,projectID,RadiatorRoom(roomID,"Überdeckt",1000.0,listOf(emitter()),listOf(emitter().copy(id=proposedID))))
        value=RadiatorRetrofitRules.putRoom(value,projectID,RadiatorRoom("66666666-6666-4666-8666-666666666666","Unterdeckt",2000.0,listOf(emitter().copy(id="77777777-7777-4777-8777-777777777777",nominalW=500.0)),listOf(emitter().copy(id="88888888-8888-4888-8888-888888888888"))))
        val result=RadiatorRetrofitRules.summary(value.projects.single(),scenarioID)
        assertEquals(2500.0,result.existingW,1e-9);assertEquals(4000.0,result.proposedW,1e-9)
        assertEquals(1500.0,result.existingShortfallW,1e-9);assertEquals(0.0,result.proposedShortfallW,1e-9)
        assertEquals(2,result.rooms.size)
    }
    @Test fun alternativesAndRoomEditsKeepOriginalInputImmutableAndRejectInvalidManufacturerData() {
        val original=book();val next=RadiatorRetrofitRules.putScenario(original,projectID,scenario().copy(name="Wärmepumpe",supplyC=45.0,returnC=35.0))
        assertEquals("Normpunkt",original.projects.single().scenarios.single().name)
        assertTrue(RadiatorRetrofitRules.summary(next.projects.single(),scenarioID).proposedW<RadiatorRetrofitRules.summary(original.projects.single(),scenarioID).proposedW)
        rejects {RadiatorRetrofitRules.values(emitter().copy(exponent=0.0),scenario())}
        rejects {RadiatorRetrofitRules.values(emitter().copy(nominalW=Double.NaN),scenario())}
        rejects {RadiatorRetrofitRules.values(emitter().copy(count=-1),scenario())}
        rejects {RadiatorRetrofitRules.values(emitter(),scenario().copy(returnC=10.0))}
        rejects {RadiatorRetrofitRules.putRoom(original,projectID,original.projects.single().rooms.single().copy(heatLoadW=-1.0))}
    }
    @Test fun savedReportAndRealArchiveRetainManufacturerAndScenarioFactsAcrossFailures() {
        val value=book();val de=RadiatorRetrofitRules.report(value,projectID,false);val en=RadiatorRetrofitRules.report(value,projectID,true)
        for(text in listOf(de,en)){assertTrue(text.contains("Altbau Nord"));assertTrue(text.contains("Wohnzimmer"));assertTrue(text.contains("Hersteller Typ22"));assertTrue(text.contains("ΔT50"));assertTrue(text.contains("Normpunkt"));assertTrue(text.contains("W"))}
        assertTrue(de.contains("Fehlleistung"));assertTrue(en.contains("shortfall"))
        val directory=Files.createTempDirectory("radiator-retrofit-").toFile()
        try {
            val file=File(directory,"retrofit.json");val store=RadiatorRetrofitFile(file)
            val first=RadiatorRetrofitRules.addProject(RadiatorRetrofitBook(),projectID,"Kaltstart");store.save(first,0);assertEquals(first,store.load())
            val next=RadiatorRetrofitRules.putScenario(first,projectID,scenario());val old=file.readBytes()
            rejects {RadiatorRetrofitFile(file){_,_->throw java.io.IOException("synthetic")}.save(next,first.revision)};assertArrayEquals(old,file.readBytes())
            store.save(next,first.revision);store.save(next,first.revision);assertEquals(next,RadiatorRetrofitFile(file).load())
            val json=RadiatorRetrofitCodec.encode(value);assertEquals(value,RadiatorRetrofitCodec.decode(json));rejects {RadiatorRetrofitCodec.decode(json+" junk")}
            for(bad in listOf("broken","{\"schema\":99}",json+" extra")){file.writeText(bad);val bytes=file.readBytes();rejects {store.load()};rejects {store.save(next,first.revision)};assertArrayEquals(bytes,file.readBytes())}
        } finally {directory.deleteRecursively()}
    }
}
