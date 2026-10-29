package de.kamilunavo.shk

import java.io.File
import java.nio.file.Files
import java.util.UUID
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.pow
import org.junit.Assert.*
import org.junit.Test

class PipeCircuitTest {
    private fun id(number:Int)=UUID(0,number.toLong()).toString()
    private fun rejects(block:()->Unit){try{block()}catch(_:Exception){return};fail("Expected invalid circuit to reject")}
    private fun segment(number:Int=3)=PipeSegment(id(number),"Kupfer Vorlauf",10.0,20.0,.01,2.0)
    private fun book():PipeCircuitBook {
        var value=PipeCircuitRules.addProject(PipeCircuitBook(),id(1),"Heizkreis Nord")
        value=PipeCircuitRules.putPath(value,id(1),false,PipePath(id(2),"StrangA",1000.0,listOf(segment())))
        return PipeCircuitRules.putPath(value,id(1),false,PipePath(id(4),"StrangB",300.0,listOf(segment(5).copy(name="Großer Parallelstrang",insideMM=32.0,lengthM=5.0))))
    }
    @Test fun idlePipeRetainsGeometricWaterVolumeWithoutHydraulicLoss() {
        val value=PipeCircuitRules.segment(0.0,segment())
        assertEquals(3.141592653589793,value.volumeLitres,1e-12)
        assertEquals(0.0,value.velocityMS,0.0);assertEquals(0.0,value.reynolds,0.0)
        assertEquals(0.0,value.dpPerM,0.0);assertEquals(0.0,value.lossKPa,0.0);assertEquals(0.0,value.headM,0.0)
    }
    @Test fun idleCircuitInventoryDoesNotDependOnDeclaredPathFlow() {
        val original=book();val project=original.projects.single()
        val idle=project.copy(baseline=project.baseline.map{it.copy(flowLPH=0.0)})
        val result=PipeCircuitRules.summary(idle,false)
        assertEquals(7.162831250184729,result.volumeLitres,1e-12)
        assertEquals(0.0,result.worstLossKPa,0.0);assertEquals(0.0,result.declaredFlowLPH,0.0)
    }
    @Test fun idleFlowStillRejectsInvalidPipeDimensions() {
        rejects {PipeCircuitRules.segment(0.0,segment().copy(insideMM=0.0))}
        rejects {PipeCircuitRules.segment(0.0,segment().copy(lengthM=-1.0))}
        rejects {PipeCircuitRules.segment(0.0,segment().copy(roughnessMM=Double.NaN))}
        rejects {PipeCircuitRules.segment(Double.NaN,segment())}
    }
    @Test fun laminarSegmentMatchesIndependentPoiseuilleIdentityAndVolume() {
        val pipe=segment().copy(zeta=0.0)
        val value=PipeCircuitRules.segment(10.0,pipe)
        val d=.02;val q=10.0/1000/3600
        val expectedPerM=128*(998*1.004e-6)*q/(PI*d.pow(4))
        assertTrue(value.reynolds<2300)
        assertEquals(expectedPerM,value.dpPerM,1e-10)
        assertEquals(PI*d*d/4*10*1000,value.volumeLitres,1e-12)
        assertEquals(expectedPerM*10/1000,value.lossKPa,1e-12)
        assertEquals(value.lossKPa*1000/(998*9.80665),value.headM,1e-12)
    }
    @Test fun seriesAddsSegmentLossButParallelUsesWorstPathRatherThanSum() {
        var value=book();val first=value.projects.single().baseline.first()
        val second=segment(6).copy(name="Rücklauf",lengthM=15.0,zeta=4.0)
        value=PipeCircuitRules.putSegment(value,id(1),false,first.id,second)
        val result=PipeCircuitRules.summary(value.projects.single(),false)
        val row=result.paths.single{it.pathID==first.id}
        val expected=PipeCircuitRules.segment(1000.0,segment()).lossKPa+PipeCircuitRules.segment(1000.0,second).lossKPa
        assertEquals(expected,row.lossKPa,1e-12)
        assertEquals(result.paths.maxOf{it.lossKPa},result.worstLossKPa,1e-12)
        assertTrue(result.paths.sumOf{it.lossKPa}>result.worstLossKPa)
        assertEquals(result.paths.sumOf{it.volumeLitres},result.volumeLitres,1e-12)
        assertEquals(1300.0,result.declaredFlowLPH,0.0)
    }
    @Test fun proposalChangesDoNotRewriteBaselineAndLargerDiameterReducesLoss() {
        val original=book()
        val next=PipeCircuitRules.putPath(original,id(1),true,PipePath(id(7),"Alternative",1000.0,listOf(segment(8).copy(insideMM=35.0))))
        assertTrue(original.projects.single().proposal.isEmpty())
        assertEquals(original.projects.single().baseline,next.projects.single().baseline)
        assertTrue(PipeCircuitRules.summary(next.projects.single(),true).worstLossKPa<PipeCircuitRules.summary(next.projects.single(),false).worstLossKPa)
        rejects {PipeCircuitRules.segment(1000.0,segment().copy(insideMM=0.0))}
        rejects {PipeCircuitRules.segment(1000.0,segment().copy(roughnessMM=-1.0))}
        rejects {PipeCircuitRules.segment(1000.0,segment().copy(zeta=Double.NaN))}
        rejects {PipeCircuitRules.putPath(original,id(1),false,PipePath(id(9),"Negativ",-1.0,listOf(segment(10))))}
    }
    @Test fun savedReportLabelsIndependentParallelFlowsAndExistingWaterAssumptions() {
        val value=book();val de=PipeCircuitRules.report(value,id(1),false);val en=PipeCircuitRules.report(value,id(1),true)
        for(text in listOf(de,en)){assertTrue(text.contains("Heizkreis Nord"));assertTrue(text.contains("Kupfer Vorlauf"));assertTrue(text.contains("StrangA"));assertTrue(text.contains("20 °C"));assertTrue(text.contains("Darcy"));assertTrue(text.contains("ζ"));assertTrue(text.contains("kPa"))}
        assertTrue(de.contains("ungünstigster"));assertTrue(en.contains("worst"));assertTrue(en.contains("parallel"))
    }
    @Test fun actualArchiveRetainsColdRestartAtomicFailureAndExternalInvalidBytes() {
        val directory=Files.createTempDirectory("pipe-circuit-").toFile()
        try {
            val file=File(directory,"circuits.json");val store=PipeCircuitFile(file)
            val first=PipeCircuitRules.addProject(PipeCircuitBook(),id(1),"Kaltstart");store.save(first,0);assertEquals(first,store.load())
            val next=PipeCircuitRules.putPath(first,id(1),false,PipePath(id(2),"Serie",1000.0,listOf(segment())))
            val old=file.readBytes();rejects {PipeCircuitFile(file){_,_->throw java.io.IOException("synthetic")}.save(next,first.revision)};assertArrayEquals(old,file.readBytes())
            store.save(next,first.revision);store.save(next,first.revision);assertEquals(next,PipeCircuitFile(file).load())
            rejects {store.save(first,first.revision)}
            val json=PipeCircuitCodec.encode(book());assertEquals(book(),PipeCircuitCodec.decode(json));rejects {PipeCircuitCodec.decode(json+" trailing")}
            rejects {PipeCircuitCodec.encode(next.copy(projects=next.projects+next.projects.single()))}
            for(bad in listOf("broken","{\"schema\":99}",json+" junk")){file.writeText(bad);val bytes=file.readBytes();rejects {store.load()};rejects {store.save(next,first.revision)};assertArrayEquals(bytes,file.readBytes())}
        } finally {directory.deleteRecursively()}
    }
}
