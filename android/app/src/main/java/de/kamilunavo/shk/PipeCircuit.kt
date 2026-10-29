package de.kamilunavo.shk

import java.util.Locale
import java.util.UUID
import kotlin.math.*

data class PipeSegment(val id:String,val name:String,val lengthM:Double,val insideMM:Double,val roughnessMM:Double,val zeta:Double)
data class PipePath(val id:String,val name:String,val flowLPH:Double,val segments:List<PipeSegment> = emptyList())
data class PipeCircuitProject(val id:String,val name:String,val baseline:List<PipePath> = emptyList(),val proposal:List<PipePath> = emptyList())
data class PipeCircuitBook(val schema:Int=1,val revision:Int=0,val projects:List<PipeCircuitProject> = emptyList())
data class PipeSegmentValues(val velocityMS:Double,val reynolds:Double,val dpPerM:Double,val lossKPa:Double,val headM:Double,val volumeLitres:Double)
data class PipePathValues(val pathID:String,val name:String,val flowLPH:Double,val lossKPa:Double,val headM:Double,val volumeLitres:Double)
data class PipeCircuitValues(val paths:List<PipePathValues>,val worstLossKPa:Double,val volumeLitres:Double,val declaredFlowLPH:Double)

object PipeCircuitRules {
    private fun id(value:String){require(runCatching{UUID.fromString(value).toString()==value}.getOrDefault(false)){"Invalid circuit identity"}}
    private fun name(value:String){require(value.isNotBlank()&&value==value.trim()&&value.length<=120){"Invalid circuit name"}}
    private fun checkSegment(value:PipeSegment){id(value.id);name(value.name);require(value.lengthM.isFinite()&&value.lengthM in 0.0..100000.0&&value.insideMM.isFinite()&&value.insideMM in .1..10000.0&&value.roughnessMM.isFinite()&&value.roughnessMM in 0.0..100.0&&value.zeta.isFinite()&&value.zeta in 0.0..10000.0){"Invalid pipe geometry"}}
    fun segment(flowLPH:Double,value:PipeSegment):PipeSegmentValues {
        checkSegment(value);require(flowLPH.isFinite()&&flowLPH in 0.0..1000000.0){"Invalid declared path flow"}
        val diameterM=value.insideMM/1000
        val volumeLitres=PI*diameterM*diameterM/4*value.lengthM*1000
        if(flowLPH==0.0)return PipeSegmentValues(0.0,0.0,0.0,0.0,0.0,volumeLitres)
        // Exact existing RohrCalc water-near20C expressions, no network solution.
        val d=value.insideMM/1000;val area=PI*d*d/4;val q=flowLPH/1000/3600;val velocity=q/area;val re=velocity*d/1.004e-6
        val friction=if(re in 0.0..2299.999)64/re else 1/(-1.8*log10((max(0.0,value.roughnessMM/1000)/d/3.7).pow(1.11)+6.9/re)).pow(2)
        val dp=friction*(998*velocity*velocity/2)/d;val local=max(0.0,value.zeta)*(998*velocity*velocity/2)/1000;val loss=dp*max(0.0,value.lengthM)/1000+local
        return PipeSegmentValues(velocity,re,dp,loss,loss*1000/(998*9.80665),volumeLitres).also {require(listOf(it.velocityMS,it.reynolds,it.dpPerM,it.lossKPa,it.headM,it.volumeLitres).all(Double::isFinite)){"Pipe result outside numeric range"}}
    }
    internal fun validate(book:PipeCircuitBook) {
        require(book.schema==1&&book.revision>=0&&book.projects.size<=20){"Unsupported circuit archive"};val ids=HashSet<String>()
        fun unique(value:String){id(value);require(ids.add(value)){"Duplicate circuit identity"}}
        book.projects.forEach {project->
            unique(project.id);name(project.name);require(project.baseline.size<=10&&project.proposal.size<=10){"Circuit path capacity"}
            (project.baseline+project.proposal).forEach{path->
                unique(path.id);name(path.name);require(path.flowLPH.isFinite()&&path.flowLPH in 0.0..1000000.0&&path.segments.size<=30){"Invalid declared circuit path"}
                path.segments.forEach{unique(it.id);checkSegment(it);segment(path.flowLPH,it)}
            }
        }
    }
    private fun update(book:PipeCircuitBook,projectID:String,action:(PipeCircuitProject)->PipeCircuitProject):PipeCircuitBook {
        validate(book);require(book.projects.any{it.id==projectID}){"Unknown circuit project"}
        return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects.map{if(it.id==projectID)action(it)else it}).also(::validate)
    }
    fun addProject(book:PipeCircuitBook,id:String,name:String):PipeCircuitBook {validate(book);return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects+PipeCircuitProject(id,name)).also(::validate)}
    fun putPath(book:PipeCircuitBook,projectID:String,proposal:Boolean,path:PipePath)=update(book,projectID){project->
        val values=if(proposal)project.proposal else project.baseline;val copy=path.copy(segments=path.segments.toList())
        val changed=if(values.any{it.id==path.id})values.map{if(it.id==path.id)copy else it}else values+copy
        if(proposal)project.copy(proposal=changed)else project.copy(baseline=changed)
    }
    fun putSegment(book:PipeCircuitBook,projectID:String,proposal:Boolean,pathID:String,value:PipeSegment):PipeCircuitBook {
        validate(book);val project=book.projects.single{it.id==projectID};val path=(if(proposal)project.proposal else project.baseline).single{it.id==pathID}
        return putPath(book,projectID,proposal,path.copy(segments=if(path.segments.any{it.id==value.id})path.segments.map{if(it.id==value.id)value else it}else path.segments+value))
    }
    fun summary(project:PipeCircuitProject,proposal:Boolean):PipeCircuitValues {
        validate(PipeCircuitBook(projects=listOf(project)))
        val paths=(if(proposal)project.proposal else project.baseline).map {path->
            val values=path.segments.map{segment(path.flowLPH,it)};val loss=values.sumOf{it.lossKPa}
            PipePathValues(path.id,path.name,path.flowLPH,loss,loss*1000/(998*9.80665),values.sumOf{it.volumeLitres})
        }
        return PipeCircuitValues(paths,paths.maxOfOrNull{it.lossKPa}?:0.0,paths.sumOf{it.volumeLitres},paths.sumOf{it.flowLPH})
    }
    fun report(book:PipeCircuitBook,projectID:String,english:Boolean):String {
        validate(book);val project=book.projects.single{it.id==projectID};val locale=if(english)Locale.US else Locale.GERMANY
        fun t(de:String,en:String)=if(english)en else de
        fun number(value:Double)=String.format(locale,"%.3f",value)
        return buildString {
            appendLine("RohrCalc · "+t("Rohrkreisvergleich","Circuit comparison"));appendLine(project.name)
            appendLine(t("Wasser nahe20 °C · Darcy-Weisbach / bestehende Reibungsnäherung. Volumenstrom je Parallelpfad vom Anwender, keine Netzberechnung oder Pumpenauswahl.","Water near20 °C · Darcy-Weisbach / existing friction approximation. User-declared flow per parallel path, no network solution or pump selection."))
            for(proposal in listOf(false,true)) {
                appendLine();appendLine(if(proposal)t("Vorschlag","Proposal")else t("Bestand","Baseline"))
                val result=summary(project,proposal)
                (if(proposal)project.proposal else project.baseline).forEach {path->
                    appendLine(path.name+" · ${number(path.flowLPH)} l/h · "+t("Segmente in Reihe","segments in series"))
                    path.segments.forEach {piece->
                        val values=segment(path.flowLPH,piece)
                        appendLine("${piece.name} · ${number(piece.lengthM)} m · Øi ${number(piece.insideMM)} mm · "+t("Rauheit ","Roughness ")+number(piece.roughnessMM)+" mm · ζ ${number(piece.zeta)}")
                        appendLine("  ${number(values.lossKPa)} kPa · ${number(values.dpPerM)} Pa/m · ${number(values.velocityMS)} m/s · Re ${number(values.reynolds)}")
                    }
                    val values=result.paths.single{it.pathID==path.id};appendLine(t("Pfadsumme: ","Path total: ")+number(values.lossKPa)+" kPa · ${number(values.volumeLitres)} l")
                    if(path.segments.isEmpty())appendLine(t("Noch keine Segmente; keine vollständige Auslegung.","No segments yet; not a complete design."))
                }
                appendLine(t("ungünstigster Parallelpfad (Maximum, keine Summe): ","worst parallel path (maximum, not sum): ")+number(result.worstLossKPa)+" kPa")
                appendLine(t("Gesamtvolumen / deklarierter Gesamtstrom: ","Total volume / declared total flow: ")+number(result.volumeLitres)+" l / ${number(result.declaredFlowLPH)} l/h")
            }
            append(t("Temperatur, Glykol und andere Medien verändern die Ergebnisse. Fachplanung und Herstellerangaben haben Vorrang.","Temperature, glycol and other media change results. Professional design and manufacturer data take precedence."))
        }
    }
}
