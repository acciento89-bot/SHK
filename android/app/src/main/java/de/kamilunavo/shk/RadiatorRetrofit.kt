package de.kamilunavo.shk

import java.util.Locale
import java.util.UUID
import kotlin.math.abs
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.pow

data class RadiatorEmitter(val id:String,val name:String,val nominalW:Double,val exponent:Double,val count:Int)
data class RadiatorScenario(val id:String,val name:String,val supplyC:Double,val returnC:Double,val roomC:Double)
data class RadiatorRoom(val id:String,val name:String,val heatLoadW:Double,val existing:List<RadiatorEmitter>,val proposed:List<RadiatorEmitter>)
data class RadiatorRetrofitProject(val id:String,val name:String,val rooms:List<RadiatorRoom> = emptyList(),val scenarios:List<RadiatorScenario> = emptyList())
data class RadiatorRetrofitBook(val schema:Int=1,val revision:Int=0,val projects:List<RadiatorRetrofitProject> = emptyList())
data class RadiatorValues(val actualW:Double,val overtemperatureK:Double,val logarithmic:Boolean,val flowLPH:Double)
data class RadiatorRoomCapacity(val roomID:String,val name:String,val heatLoadW:Double,val existingW:Double,val proposedW:Double,val existingShortfallW:Double,val proposedShortfallW:Double)
data class RadiatorRetrofitSummary(val existingW:Double,val proposedW:Double,val existingShortfallW:Double,val proposedShortfallW:Double,val heatLoadW:Double,val rooms:List<RadiatorRoomCapacity>)

object RadiatorRetrofitRules {
    private fun id(value:String){require(runCatching{UUID.fromString(value).toString()==value}.getOrDefault(false)){"Invalid retrofit identity"}}
    private fun name(value:String){require(value.isNotBlank()&&value==value.trim()&&value.length<=120){"Invalid retrofit name"}}
    private fun validateEmitter(value:RadiatorEmitter){id(value.id);name(value.name);require(value.nominalW.isFinite()&&value.nominalW>0&&value.nominalW<=1000000&&value.exponent.isFinite()&&value.exponent>0&&value.exponent<=5&&value.count in 1..100){"Invalid manufacturer data"}}
    private fun validateScenario(value:RadiatorScenario){id(value.id);name(value.name);require(listOf(value.supplyC,value.returnC,value.roomC).all{it.isFinite()&&it in -100.0..200.0}&&value.supplyC>=value.returnC&&value.returnC>value.roomC){"Invalid operating temperatures"}}
    fun values(emitter:RadiatorEmitter,scenario:RadiatorScenario):RadiatorValues {
        validateEmitter(emitter);validateScenario(scenario)
        // Exact existing HeizkörperCalc selection and reference expressions.
        val arithmetic=max(0.0,(scenario.supplyC+scenario.returnC)/2-scenario.roomC)
        val ratioC=if(scenario.supplyC>scenario.roomC)(scenario.returnC-scenario.roomC)/(scenario.supplyC-scenario.roomC)else 0.0
        val logarithmic=if(scenario.supplyC>=scenario.returnC&&scenario.supplyC>scenario.roomC&&scenario.returnC>scenario.roomC&&abs(scenario.supplyC-scenario.returnC)>1e-6)(scenario.supplyC-scenario.returnC)/ln((scenario.supplyC-scenario.roomC)/(scenario.returnC-scenario.roomC))else arithmetic
        val useLog=ratioC>0&&ratioC<.7
        val delta=if(useLog)logarithmic else arithmetic
        val reference=if(useLog)(75.0-65.0)/ln((75.0-20.0)/(65.0-20.0))else 50.0
        val actual=emitter.nominalW*(delta/reference).pow(emitter.exponent)*emitter.count
        val flow=if(actual>0&&scenario.supplyC>scenario.returnC)actual/(1.163*(scenario.supplyC-scenario.returnC))else 0.0
        require(actual.isFinite()&&flow.isFinite()){ "Radiator result outside numeric range" }
        return RadiatorValues(actual,delta,useLog,flow)
    }
    internal fun validate(book:RadiatorRetrofitBook) {
        require(book.schema==1&&book.revision>=0&&book.projects.size<=20){"Unsupported retrofit archive"};val ids=HashSet<String>()
        fun unique(value:String){id(value);require(ids.add(value)){"Duplicate retrofit identity"}}
        book.projects.forEach{project->
            unique(project.id);name(project.name);require(project.rooms.size<=40&&project.scenarios.size<=6){"Retrofit project capacity"}
            project.scenarios.forEach{validateScenario(it);unique(it.id)}
            project.rooms.forEach {room->
                unique(room.id);name(room.name);require(room.heatLoadW.isFinite()&&room.heatLoadW in 0.0..1000000.0&&room.existing.size<=20&&room.proposed.size<=20){"Invalid room heat requirement"}
                (room.existing+room.proposed).forEach{validateEmitter(it);unique(it.id)}
            }
        }
    }
    private fun update(book:RadiatorRetrofitBook,projectID:String,action:(RadiatorRetrofitProject)->RadiatorRetrofitProject):RadiatorRetrofitBook {
        validate(book);require(book.projects.any{it.id==projectID}){"Unknown retrofit project"}
        return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects.map{if(it.id==projectID)action(it)else it}).also(::validate)
    }
    fun addProject(book:RadiatorRetrofitBook,id:String,name:String):RadiatorRetrofitBook {validate(book);return book.copy(revision=Math.addExact(book.revision,1),projects=book.projects+RadiatorRetrofitProject(id,name)).also(::validate)}
    fun putScenario(book:RadiatorRetrofitBook,projectID:String,value:RadiatorScenario)=update(book,projectID){project->project.copy(scenarios=if(project.scenarios.any{it.id==value.id})project.scenarios.map{if(it.id==value.id)value else it}else project.scenarios+value)}
    fun putRoom(book:RadiatorRetrofitBook,projectID:String,value:RadiatorRoom)=update(book,projectID){project->
        val copied=value.copy(existing=value.existing.toList(),proposed=value.proposed.toList())
        project.copy(rooms=if(project.rooms.any{it.id==value.id})project.rooms.map{if(it.id==value.id)copied else it}else project.rooms+copied)
    }
    fun summary(project:RadiatorRetrofitProject,scenarioID:String):RadiatorRetrofitSummary {
        validate(RadiatorRetrofitBook(projects=listOf(project)));val scenario=project.scenarios.single{it.id==scenarioID}
        val rooms=project.rooms.map {room->
            val existing=room.existing.sumOf{values(it,scenario).actualW};val proposed=room.proposed.sumOf{values(it,scenario).actualW}
            RadiatorRoomCapacity(room.id,room.name,room.heatLoadW,existing,proposed,max(0.0,room.heatLoadW-existing),max(0.0,room.heatLoadW-proposed))
        }
        return RadiatorRetrofitSummary(rooms.sumOf{it.existingW},rooms.sumOf{it.proposedW},rooms.sumOf{it.existingShortfallW},rooms.sumOf{it.proposedShortfallW},rooms.sumOf{it.heatLoadW},rooms)
    }
    fun report(book:RadiatorRetrofitBook,projectID:String,english:Boolean):String {
        validate(book);val project=book.projects.single{it.id==projectID};val locale=if(english)Locale.US else Locale.GERMANY
        fun t(de:String,en:String)=if(english)en else de
        fun number(value:Double)=String.format(locale,"%.2f",value)
        return buildString {
            appendLine("HeizkörperCalc · "+t("Modernisierungsaufnahme","Retrofit survey"));appendLine(project.name)
            appendLine(t("Raum-Heizlast und Herstellerdaten vom Anwender; Nennleistung bei ΔT50 und Exponent n. Keine automatische Heizlastberechnung oder Freigabe.","User-supplied room heat requirements and manufacturer data; nominal output at ΔT50 and exponent n. No automatic heat-load calculation or approval."))
            project.rooms.forEach {room->
                appendLine();appendLine(room.name+" · "+t("Heizlast: ","Heat requirement: ")+number(room.heatLoadW)+" W")
                for(proposed in listOf(false,true)) {
                    appendLine(if(proposed)t("Vorschlag","Proposed")else t("Bestand","Existing"))
                    (if(proposed)room.proposed else room.existing).forEach{appendLine("${it.name} · ΔT50 ${number(it.nominalW)} W · n ${number(it.exponent)} · "+t("Anzahl ","Count ")+it.count)}
                }
            }
            project.scenarios.forEach {scenario->
                appendLine();appendLine(scenario.name+" · ${number(scenario.supplyC)} / ${number(scenario.returnC)} / ${number(scenario.roomC)} °C")
                val result=summary(project,scenario.id)
                result.rooms.forEach{room->
                    appendLine(room.name+" · "+t("Bestand / Vorschlag","Existing / Proposed")+": ${number(room.existingW)} / ${number(room.proposedW)} W")
                    appendLine(t("Fehlleistung Bestand / Vorschlag","Capacity shortfall existing / proposed")+": ${number(room.existingShortfallW)} / ${number(room.proposedShortfallW)} W")
                }
                appendLine(t("Gesamtleistung Bestand / Vorschlag","Total capacity existing / proposed")+": ${number(result.existingW)} / ${number(result.proposedW)} W")
                appendLine(t("Summe raumweiser Fehlleistung","Sum of per-room shortfall")+": ${number(result.existingShortfallW)} / ${number(result.proposedShortfallW)} W")
                val sample=project.rooms.flatMap{it.existing+it.proposed}.firstOrNull()
                if(sample!=null){val point=values(sample,scenario);appendLine(t("Übertemperatur: ","Overtemperature: ")+number(point.overtemperatureK)+" K · "+if(point.logarithmic)t("logarithmisch; Referenz 75/65/20","logarithmic; reference75/65/20")else t("arithmetisch; Referenz50K","arithmetic; reference50K"))}
            }
            append(t("Überschüsse anderer Räume heben Fehlleistung nicht auf. Herstellerangaben und objektspezifische Planung haben Vorrang.","Surplus in other rooms does not cancel capacity shortfall. Manufacturer data and project-specific design take precedence."))
        }
    }
}
