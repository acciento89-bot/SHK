package de.kamilunavo.shk

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.Locale
import java.util.UUID
import kotlin.math.max

data class ServiceInstallation(val id:String,val name:String)
data class ServiceChecklistItem(val id:String,val label:String)
data class ServiceTemplate(val id:String,val name:String,val version:Int,val items:List<ServiceChecklistItem>)
data class ServiceMeasurements(val flowC:Double,val returnC:Double,val coldBar:Double,val hotBar:Double,val staticHeightM:Double,val safetyValveBar:Double)
data class ServiceLimits(val minColdBar:Double,val maxColdBar:Double)
data class ServiceVisit(val id:String,val installationID:String,val recordedAt:String,val measurements:ServiceMeasurements,val limits:ServiceLimits,val template:ServiceTemplate,val checked:List<String>,val notes:String,val nextServiceDate:String?)
data class ServiceHistoryBook(val schema:Int=1,val revision:Int=0,val installations:List<ServiceInstallation> = emptyList(),val templates:List<ServiceTemplate> = emptyList(),val visits:List<ServiceVisit> = emptyList())
data class ServiceCheckValues(val spreadK:Double,val pressureRiseBar:Double,val staticMinimumBar:Double,val valveMarginBar:Double,val warningCount:Int)
data class ServiceDue(val installationID:String,val name:String,val date:String)

object ServiceHistoryRules {
    private fun id(value:String){require(runCatching{UUID.fromString(value).toString()==value}.getOrDefault(false)){"Invalid service history identity"}}
    private fun name(value:String){require(value.isNotBlank()&&value==value.trim()&&value.length<=120){"Invalid service label"}}
    private fun template(value:ServiceTemplate){id(value.id);name(value.name);require(value.version>=1&&value.items.size in 1..30){"Invalid checklist version"};val ids=HashSet<String>();value.items.forEach{id(it.id);name(it.label);require(ids.add(it.id)){"Duplicate checklist item"}}}
    fun values(measurements:ServiceMeasurements,limits:ServiceLimits):ServiceCheckValues {
        require(listOf(measurements.flowC,measurements.returnC).all{it.isFinite()&&it in -50.0..200.0}){"Invalid measured temperatures"}
        require(listOf(measurements.coldBar,measurements.hotBar).all{it.isFinite()&&it in -1.0..100.0}&&measurements.staticHeightM.isFinite()&&measurements.staticHeightM in 0.0..1000.0&&measurements.safetyValveBar.isFinite()&&measurements.safetyValveBar>0&&measurements.safetyValveBar<=100){"Invalid measured pressure or height"}
        require(limits.minColdBar.isFinite()&&limits.maxColdBar.isFinite()&&limits.minColdBar in 0.0..100.0&&limits.maxColdBar in limits.minColdBar..100.0){"Invalid own pressure limits"}
        val spread=measurements.flowC-measurements.returnC;val rise=measurements.hotBar-measurements.coldBar
        val minimum=max(0.0,measurements.staticHeightM)*.0980665+.3;val margin=measurements.safetyValveBar-measurements.hotBar
        val warnings=listOf(spread<0||spread<5||spread>20,measurements.coldBar<limits.minColdBar||measurements.coldBar>limits.maxColdBar,measurements.coldBar<minimum,rise<0||rise>1,margin<.5).count{it}
        return ServiceCheckValues(spread,rise,minimum,margin,warnings)
    }
    internal fun validate(book:ServiceHistoryBook) {
        require(book.schema==1&&book.revision>=0&&book.installations.size<=40&&book.templates.size<=30&&book.visits.size<=400){"Unsupported service history archive"}
        val claims=HashMap<String,Pair<String,String>>()
        fun claim(value:String,kind:String,owner:String,repeated:Boolean=false){id(value);val old=claims[value];require(old==null||repeated&&old==Pair(kind,owner)){"Duplicate or foreign history identity"};claims[value]=Pair(kind,owner)}
        book.installations.forEach{claim(it.id,"installation",it.id);name(it.name)}
        val versions=HashMap<Pair<String,Int>,ServiceTemplate>()
        fun snapshot(value:ServiceTemplate){template(value);claim(value.id,"template",value.id,true);value.items.forEach{claim(it.id,"item",value.id,true)};val key=Pair(value.id,value.version);val old=versions[key];require(old==null||old==value){"Checklist version changed facts"};versions[key]=value}
        val templateIDs=HashSet<String>()
        book.templates.forEach{require(templateIDs.add(it.id)){"Duplicate current template"};snapshot(it)}
        val installations=book.installations.map{it.id}.toSet()
        book.visits.forEach {visit->
            claim(visit.id,"visit",visit.installationID);require(visit.installationID in installations&&visit.notes.length<=2000){"Invalid service visit owner"}
            val instant=Instant.parse(visit.recordedAt);require(instant.toString()==visit.recordedAt){"Invalid UTC service time"}
            values(visit.measurements,visit.limits);snapshot(visit.template)
            val current=book.templates.singleOrNull{it.id==visit.template.id};require(current!=null&&visit.template.version<=current.version){"Foreign checklist snapshot"}
            val items=visit.template.items.map{it.id}.toSet();require(visit.checked.size==visit.checked.toSet().size&&visit.checked.all{it in items}){"Foreign checked item"}
            visit.nextServiceDate?.let{date->val parsed=LocalDate.parse(date);require(parsed.toString()==date&&!parsed.isBefore(instant.atOffset(ZoneOffset.UTC).toLocalDate())){"Invalid next-service date"}}
        }
    }
    fun addInstallation(book:ServiceHistoryBook,value:ServiceInstallation):ServiceHistoryBook {validate(book);return book.copy(revision=Math.addExact(book.revision,1),installations=book.installations+value).also(::validate)}
    fun addTemplate(book:ServiceHistoryBook,value:ServiceTemplate):ServiceHistoryBook {validate(book);require(value.version==1){"New checklist starts at version1"};return book.copy(revision=Math.addExact(book.revision,1),templates=book.templates+value.copy(items=value.items.toList())).also(::validate)}
    fun reviseTemplate(book:ServiceHistoryBook,templateID:String,name:String,items:List<ServiceChecklistItem>):ServiceHistoryBook {
        validate(book);val old=book.templates.single{it.id==templateID};val next=old.copy(name=name,version=Math.addExact(old.version,1),items=items.toList())
        return book.copy(revision=Math.addExact(book.revision,1),templates=book.templates.map{if(it.id==templateID)next else it}).also(::validate)
    }
    fun addVisit(book:ServiceHistoryBook,value:ServiceVisit):ServiceHistoryBook {
        validate(book);require(book.templates.singleOrNull{it.id==value.template.id}==value.template){"Select current checklist version"}
        val copied=value.copy(template=value.template.copy(items=value.template.items.toList()),checked=value.checked.toList())
        return book.copy(revision=Math.addExact(book.revision,1),visits=book.visits+copied).also(::validate)
    }
    fun nextServices(book:ServiceHistoryBook):List<ServiceDue> {
        validate(book);return book.installations.mapNotNull {installation->
            val latest=book.visits.filter{it.installationID==installation.id}.maxByOrNull{Instant.parse(it.recordedAt)}
            latest?.nextServiceDate?.let{ServiceDue(installation.id,installation.name,it)}
        }.sortedBy{LocalDate.parse(it.date)}
    }
    fun report(book:ServiceHistoryBook,installationID:String,english:Boolean):String {
        validate(book);val installation=book.installations.single{it.id==installationID};val locale=if(english)Locale.US else Locale.GERMANY
        fun t(de:String,en:String)=if(english)en else de
        fun number(value:Double)=String.format(locale,"%.2f",value)
        return buildString {
            appendLine("AnlagenCheck · "+t("Servicehistorie","Service history"));appendLine(installation.name)
            appendLine(t("Keine Sicherheitsfreigabe. Eigene Vorgaben und dokumentierte Sicht-/Messprüfungen; Hersteller, Normen und Fachbeurteilung haben Vorrang.","No safety approval. User-defined limits and recorded observations/readings; manufacturer data, standards and professional assessment take precedence."))
            book.visits.filter{it.installationID==installationID}.sortedBy{Instant.parse(it.recordedAt)}.forEach {visit->
                val m=visit.measurements;val result=values(m,visit.limits)
                appendLine();appendLine(visit.recordedAt+" UTC");appendLine("${visit.template.name} · Version ${visit.template.version}")
                appendLine(t("Vorlauf / Rücklauf","Supply / return")+": ${number(m.flowC)} / ${number(m.returnC)} °C · ${number(result.spreadK)} K")
                appendLine(t("Kalt / Warm","Cold / hot")+": ${number(m.coldBar)} / ${number(m.hotBar)} bar · "+t("Anstieg ","Rise ")+number(result.pressureRiseBar)+" bar")
                appendLine(t("Eigene Kalt-Druckgrenzen","User cold-pressure limits")+": ${number(visit.limits.minColdBar)} / ${number(visit.limits.maxColdBar)} bar")
                appendLine(t("Höhe / statische Mindestvorgabe","Height / static minimum")+": ${number(m.staticHeightM)} m / ${number(result.staticMinimumBar)} bar")
                appendLine(t("Sicherheitsventil / Reserve","Safety valve / margin")+": ${number(m.safetyValveBar)} / ${number(result.valveMarginBar)} bar")
                appendLine(result.warningCount.toString()+t(" Prüfhinweise"," measurement warnings"))
                visit.template.items.forEach{appendLine((if(it.id in visit.checked)"[x] "else "[ ] ")+it.label)}
                appendLine(t("Notiz: ","Note: ")+visit.notes)
                appendLine(t("Nächster Service (lokales Datum, keine Systembenachrichtigung): ","Next service (local date, no system notification): ")+(visit.nextServiceDate?:t("nicht festgelegt","not set")))
            }
        }
    }
}
