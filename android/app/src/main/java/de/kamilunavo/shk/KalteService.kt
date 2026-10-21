package de.kamilunavo.shk

import java.time.Instant
import java.util.Locale
import java.util.UUID
import kotlin.math.abs

data class KalteReading(
    val evaporationC:Double,val suctionC:Double,val condensationC:Double,val liquidC:Double,
    val suctionGaugeBar:Double,val dischargeGaugeBar:Double,val airFlowM3H:Double,val enteringAirC:Double,val leavingAirC:Double
)
data class KalteValues(val superheatK:Double,val subcoolingK:Double,val compressorRatio:Double,val sensibleKW:Double)
data class KalteAsset(val id:String,val name:String)
data class KalteVisit(val id:String,val assetID:String,val recordedAt:String,val before:KalteReading,val after:KalteReading,val notes:String)
data class KalteServiceBook(val schema:Int=1,val revision:Int=0,val assets:List<KalteAsset> = emptyList(),val visits:List<KalteVisit> = emptyList())

object KalteServiceRules {
    internal fun identity(value:String) {require(runCatching {UUID.fromString(value).toString()==value}.getOrDefault(false)){"Invalid service identity"}}
    private fun text(value:String,maximum:Int,required:Boolean=false) {require(value.length<=maximum && (!required || value.isNotBlank())){"Invalid service text"}}
    fun values(reading:KalteReading):KalteValues {
        listOf(reading.evaporationC,reading.suctionC,reading.condensationC,reading.liquidC,reading.enteringAirC,reading.leavingAirC).forEach {require(it.isFinite() && it in -200.0..300.0){"Invalid measured temperature"}}
        listOf(reading.suctionGaugeBar,reading.dischargeGaugeBar).forEach {require(it.isFinite() && it+1.01325>0 && it<=1000){"Gauge pressure needs positive absolute pressure"}}
        require(reading.airFlowM3H.isFinite() && reading.airFlowM3H in 0.0..100000.0){"Invalid air volume flow"}
        // Exact existing Android calculator expressions; saturation temperatures are supplied by the user.
        return KalteValues(reading.suctionC-reading.evaporationC,reading.condensationC-reading.liquidC,
            (reading.dischargeGaugeBar+1.01325)/(reading.suctionGaugeBar+1.01325),reading.airFlowM3H*abs(reading.enteringAirC-reading.leavingAirC)*0.000335).also {
            require(listOf(it.superheatK,it.subcoolingK,it.compressorRatio,it.sensibleKW).all(Double::isFinite)){"Calculation overflow"}
        }
    }
    fun delta(before:KalteReading,after:KalteReading):KalteValues {
        val first=values(before);val last=values(after)
        return KalteValues(last.superheatK-first.superheatK,last.subcoolingK-first.subcoolingK,last.compressorRatio-first.compressorRatio,last.sensibleKW-first.sensibleKW)
    }
    internal fun validate(book:KalteServiceBook) {
        require(book.schema==1 && book.revision>=0){"Unknown or invalid service archive"}
        require(book.assets.size<=40 && book.visits.size<=400){"Service archive limit"}
        val ids=HashSet<String>()
        book.assets.forEach {identity(it.id);require(ids.add(it.id)){"Duplicate appliance"};text(it.name,120,true);require(it.name==it.name.trim()){ "Untrimmed appliance name" }}
        val assets=book.assets.map{it.id}.toSet()
        book.visits.forEach {
            identity(it.id);identity(it.assetID);require(ids.add(it.id) && it.assetID in assets){"Duplicate or foreign service visit"}
            require(runCatching {Instant.parse(it.recordedAt).toString()==it.recordedAt}.getOrDefault(false)){"Invalid UTC visit time"}
            text(it.notes,2000);values(it.before);values(it.after)
        }
    }
    fun addAsset(book:KalteServiceBook,asset:KalteAsset):KalteServiceBook {
        validate(book)
        return book.copy(revision=Math.addExact(book.revision,1),assets=book.assets+asset,visits=book.visits.toList()).also(::validate)
    }
    fun addVisit(book:KalteServiceBook,visit:KalteVisit):KalteServiceBook {
        validate(book)
        return book.copy(revision=Math.addExact(book.revision,1),assets=book.assets.toList(),visits=book.visits+visit).also(::validate)
    }
    fun removeAsset(book:KalteServiceBook,assetID:String):KalteServiceBook {
        validate(book);identity(assetID);require(book.assets.any{it.id==assetID} && book.visits.none{it.assetID==assetID}){"Appliance has saved history"}
        return book.copy(revision=Math.addExact(book.revision,1),assets=book.assets.filterNot{it.id==assetID},visits=book.visits.toList()).also(::validate)
    }
    fun report(book:KalteServiceBook,assetID:String,english:Boolean):String {
        validate(book);val asset=book.assets.single{it.id==assetID};val locale=if(english)Locale.US else Locale.GERMANY
        fun t(de:String,en:String)=if(english)en else de
        fun number(value:Double)=String.format(locale,"%.3f",value)
        fun readings(reading:KalteReading):String {
            val calculated=values(reading)
            return listOf(
                t("Verdampfung / Sauggas","Evaporation / suction gas")+": ${number(reading.evaporationC)} / ${number(reading.suctionC)} °C",
                t("Kondensation / Flüssigkeit","Condensation / liquid")+": ${number(reading.condensationC)} / ${number(reading.liquidC)} °C",
                t("Saugdruck / Hochdruck","Suction / discharge pressure")+": ${number(reading.suctionGaugeBar)} / ${number(reading.dischargeGaugeBar)} bar(g)",
                t("Luftmenge / Eintritt / Austritt","Air volume / entering / leaving")+": ${number(reading.airFlowM3H)} m³/h / ${number(reading.enteringAirC)} / ${number(reading.leavingAirC)} °C",
                t("Überhitzung / Unterkühlung","Superheat / subcooling")+": ${number(calculated.superheatK)} / ${number(calculated.subcoolingK)} K",
                t("Verdichter-Druckverhältnis","Compressor pressure ratio")+": ${number(calculated.compressorRatio)} : 1",
                t("Luftseitige sensible Leistung","Air-side sensible capacity")+": ${number(calculated.sensibleKW)} kW"
            ).joinToString("\n")
        }
        return buildString {
            appendLine("KälteCalc · "+t("Servicehistorie","Service history"));appendLine(asset.name)
            appendLine(t("Sättigungstemperaturen vom Anwender; keine P/T-Stoffdatenbank.","User-supplied saturation temperatures; no refrigerant P/T database."))
            appendLine(t("Druckbasis: bar(g) + 1.01325 bar = Absolutdruck; nur sensible Luftleistung, ohne latente Leistung.","Pressure basis: bar(g) + 1.01325 bar = absolute pressure; sensible air capacity only, excluding latent capacity."))
            for(visit in book.visits.filter{it.assetID==assetID}.sortedBy{Instant.parse(it.recordedAt)}) {
                appendLine();appendLine(visit.recordedAt+" · UTC");appendLine(t("Vorher","Before"));appendLine(readings(visit.before))
                appendLine(t("Nachher","After"));appendLine(readings(visit.after));val change=delta(visit.before,visit.after)
                appendLine(t("Änderung (Nachher − Vorher)","Change (After − Before)"))
                appendLine(t("Überhitzung / Unterkühlung","Superheat / subcooling")+": ${number(change.superheatK)} / ${number(change.subcoolingK)} K")
                appendLine(t("Druckverhältnis","Pressure ratio")+": ${number(change.compressorRatio)}")
                appendLine(t("Sensible Leistung","Sensible capacity")+": ${number(change.sensibleKW)} kW")
                appendLine(t("Notiz: ","Note: ")+visit.notes)
            }
            append(t("Messwerte dokumentieren keine automatische Diagnose oder Sicherheitsfreigabe.","Measurements do not constitute automatic diagnosis or safety approval."))
        }
    }
}
