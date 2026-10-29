package de.kamilunavo.shk

import android.content.Context
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.time.Instant
import java.util.Locale
import java.util.UUID

private val serviceFieldKeys=listOf("evaporation","suction","condensation","liquid","suction-pressure","discharge-pressure","air-flow","entering-air","leaving-air")

private fun serviceNumbers(reading:KalteReading)=listOf(reading.evaporationC,reading.suctionC,reading.condensationC,reading.liquidC,reading.suctionGaugeBar,reading.dischargeGaugeBar,reading.airFlowM3H,reading.enteringAirC,reading.leavingAirC).map{it.toString()}
private fun serviceReading(raw:List<String>):KalteReading? {
    if(raw.size!=9)return null
    val numbers=raw.map {it.trim().replace(',','.').toDoubleOrNull()?.takeIf(Double::isFinite)?:return null}
    val value=KalteReading(numbers[0],numbers[1],numbers[2],numbers[3],numbers[4],numbers[5],numbers[6],numbers[7],numbers[8])
    return value.takeIf {runCatching{KalteServiceRules.values(it)}.isSuccess}
}

@OptIn(androidx.compose.ui.ExperimentalComposeUiApi::class)
@Composable
fun KalteServiceScreen(onShare:(String)->Unit,onBack:()->Unit) {
    val context=LocalContext.current.applicationContext
    val repository=remember(context){KalteServiceFile(File(context.filesDir,"kalte-service-v1.json"))}
    val scope=rememberCoroutineScope()
    var english by rememberSaveable{mutableStateOf(!Locale.getDefault().language.startsWith("de"))}
    fun t(de:String,en:String)=if(english)en else de
    var book by remember{mutableStateOf<KalteServiceBook?>(null)}
    var error by remember{mutableStateOf<String?>(null)}
    var busy by remember{mutableStateOf(false)}
    var selectedAsset by rememberSaveable{mutableStateOf<String?>(null)}
    var selectedVisit by rememberSaveable{mutableStateOf<String?>(null)}
    var assetEditor by rememberSaveable{mutableStateOf(false)}
    var applianceName by rememberSaveable{mutableStateOf("")}
    var applianceID by rememberSaveable{mutableStateOf("")}
    var visitEditor by rememberSaveable{mutableStateOf(false)}
    var visitID by rememberSaveable{mutableStateOf("")}
    var visitTime by rememberSaveable{mutableStateOf("")}
    var before by rememberSaveable{mutableStateOf(List(9){""})}
    var after by rememberSaveable{mutableStateOf(List(9){""})}
    var notes by rememberSaveable{mutableStateOf("")}
    var confirmLeave by rememberSaveable{mutableStateOf(false)}
    var reloadConfirmation by rememberSaveable{mutableStateOf(false)}
    val editing=assetEditor||visitEditor
    fun leave() {if(busy)return;if(editing)confirmLeave=true else if(selectedAsset!=null){selectedAsset=null;selectedVisit=null}else onBack()}
    BackHandler {leave()}
    LaunchedEffect(repository) {
        try{book=withContext(Dispatchers.IO){repository.load()};error=null}
        catch(_:Exception){error=t("Servicearchiv konnte nicht gelesen werden. Vorhandene Daten bleiben erhalten.","The service archive could not be read. Existing data is kept.")}
    }
    fun reload() {
        if(busy)return;busy=true
        scope.launch {
            try{val saved=withContext(Dispatchers.IO){repository.load()};book=saved;error=null;assetEditor=false;visitEditor=false;selectedVisit=null}
            catch(_:Exception){error=t("Laden fehlgeschlagen. Vorhandene Daten bleiben erhalten.","Reload failed. Existing data is kept.")}
            finally{busy=false}
        }
    }
    fun save(next:KalteServiceBook,expected:Int,publish:()->Unit) {
        if(busy)return;busy=true;error=null
        scope.launch {
            try {withContext(Dispatchers.IO){repository.save(next,expected)};book=next;publish()}
            catch(_:Exception){error=t("Nicht gespeichert. Deine Eingaben bleiben erhalten. Speicher prüfen und erneut versuchen oder den gespeicherten Stand laden.","Not saved. Your input is kept. Check storage and retry, or load the saved record.")}
            finally{busy=false}
        }
    }
    fun beginVisit() {visitID=UUID.randomUUID().toString();visitTime="";before=List(9){""};after=List(9){""};notes="";visitEditor=true;selectedVisit=null}
    val current=book
    val asset=current?.assets?.find{it.id==selectedAsset}
    val visits=current?.visits?.filter{it.assetID==selectedAsset}?.sortedByDescending{Instant.parse(it.recordedAt)}.orEmpty()
    val fields=listOf(t("Verdampfung °C","Evaporation °C"),t("Sauggas °C","Suction gas °C"),t("Kondensation °C","Condensation °C"),t("Flüssigkeit °C","Liquid °C"),t("Saugdruck bar(g)","Suction pressure bar(g)"),t("Hochdruck bar(g)","Discharge pressure bar(g)"),t("Luftvolumenstrom m³/h","Air volume m³/h"),t("Luft Eintritt °C","Entering air °C"),t("Luft Austritt °C","Leaving air °C"))
    LazyColumn(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding().semantics { testTagsAsResourceId = true },contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
        if (!editing && asset == null) {
            item("landing-workspace") { KalteLandingBench(current, busy, english, { english = !english }, { leave() }, { applianceID=UUID.randomUUID().toString();applianceName="";assetEditor=true }) }
        } else {
        item("header") {
            Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick={leave()},enabled=!busy){Text(t("‹ Zurück","‹ Back"))}
                WorkflowHeading("K / S", t("KälteCalc · Servicebank","KälteCalc · Service bench"), t("ANLAGEN  →  VORHER / NACHHER", "APPLIANCES  →  BEFORE / AFTER"))
                TextButton(onClick={english=!english}){Text(if(english)"Deutsch" else "English")}
                Text(t("Lokale Vorher-/Nachher-Messungen je Anlage. Keine automatische Diagnose. Sättigungstemperaturen selbst aus verifizierter Quelle übernehmen.","Local before/after readings per appliance. No automatic diagnosis. Supply saturation temperatures from a verified source."))
            }
        }
        }
        if(busy)item("busy"){LinearProgressIndicator(Modifier.fillMaxWidth())}
        if(error!=null)item("error") {
            Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Text(error!!,color=MaterialTheme.colorScheme.error)
                OutlinedButton(onClick={if(editing)reloadConfirmation=true else reload()},enabled=!busy){Text(t("Gespeicherten Stand laden","Load saved progress"))}
            }
        }
        if(current==null)item("unavailable"){Text(t("Servicearchiv wird geladen oder ist gesperrt.","Service archive is loading or unavailable."))}
        if(current!=null && !editing && asset==null) {
            items(current.assets,key={"asset-${it.id}"}) {entry->
                DocketEntry("K", entry.name, current.visits.count{it.assetID==entry.id}.toString()+t(" gespeicherte Besuche · Vorher / Nachher", " saved visits · Before / After"), enabled = !busy) { selectedAsset=entry.id;selectedVisit=null }
            }
        }
        if(current!=null && !editing && asset==null) item("landing-notes") { Text(t("Keine automatische Diagnose. Sättigungstemperaturen aus verifizierter Quelle übernehmen. Besuche speichern Vorher-/Nachher-Werte je Anlage.", "No automatic diagnosis. Supply saturation temperatures from a verified source. Visits store before/after readings per appliance."), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        if(current!=null && assetEditor) {
            item("appliance-form") {
                Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
                    Text(t("Neue Anlage","New appliance"),style=MaterialTheme.typography.titleLarge)
                    OutlinedTextField(applianceName,{applianceName=it},enabled=!busy,label={Text(t("Anlagenbezeichnung","Appliance name"))},modifier=Modifier.fillMaxWidth(),isError=applianceName.length>120)
                    Button(onClick={
                        val next=KalteServiceRules.addAsset(current,KalteAsset(applianceID,applianceName.trim()))
                        save(next,current.revision){assetEditor=false;selectedAsset=applianceID;applianceName=""}
                    },enabled=!busy&&applianceName.trim().isNotEmpty()&&applianceName.trim().length<=120,modifier=Modifier.fillMaxWidth()){Text(t("Anlage speichern","Save appliance"))}
                }
            }
        }
        if(current!=null && asset!=null && !assetEditor && !visitEditor) {
            item("asset-title"){Text(asset.name,style=MaterialTheme.typography.titleLarge)}
            item("new-visit"){Button(onClick={beginVisit()},enabled=!busy&&current.visits.size<400,modifier=Modifier.fillMaxWidth()){Text(t("Neuen Vorher-/Nachher-Besuch erfassen","Record a new before/after visit"))}}
            if(visits.isNotEmpty())item("share-history"){OutlinedButton(onClick={onShare(KalteServiceRules.report(current,asset.id,english))},modifier=Modifier.fillMaxWidth()){Text(t("Gesamte Anlagenhistorie teilen","Share appliance history"))}}
            items(visits,key={"visit-${it.id}"}) {visit->
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(10.dp)) {
                        Text(visit.recordedAt+" · UTC")
                        val delta=KalteServiceRules.delta(visit.before,visit.after)
                        val locale=if(english)Locale.US else Locale.GERMANY
                        Text(t("Änderung Überhitzung: ","Superheat change: ")+String.format(locale,"%.2f K",delta.superheatK))
                        OutlinedButton(onClick={selectedVisit=if(selectedVisit==visit.id)null else visit.id},modifier=Modifier.fillMaxWidth()){Text(t("Vorher / Nachher / Änderungen","Before / after / changes"))}
                        if(selectedVisit==visit.id) {
                            val report=KalteServiceRules.report(current.copy(visits=listOf(visit)),asset.id,english)
                            Text(report)
                            OutlinedButton(onClick={onShare(report)},modifier=Modifier.fillMaxWidth()){Text(t("Diesen Besuch teilen","Share this visit"))}
                        }
                    }
                }
            }
            if(visits.isEmpty())item("no-visits"){Text(t("Noch keine Servicebesuche. Gespeicherte Besuche bleiben unverändert; weitere Messungen als neuen Besuch erfassen.","No service visits yet. Saved visits remain unchanged; record further readings as a new visit."))}
        }
        if(current!=null && asset!=null && visitEditor) {
            item("visit-title") {
                Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                    Text(asset.name,style=MaterialTheme.typography.titleLarge)
                    Text(t("Alle Messwerte eingeben. Drücke sind bar(g); Rechnung aus Absolutdrücken mit +1.01325 bar. Luftleistung ist nur sensibel. Vorzeichen bleiben erhalten.","Enter every reading. Pressures are bar(g); absolute pressure uses +1.01325 bar. Air capacity is sensible only. Signed differences are retained."))
                    if(visits.isNotEmpty())OutlinedButton(onClick={before=serviceNumbers(visits.first().after)},enabled=!busy){Text(t("Vorher ausdrücklich aus letztem Besuch übernehmen","Copy Before from last visit explicitly"))}
                }
            }
            for(stage in 0..1) {
                item("stage-$stage"){Text(if(stage==0)t("Vorher","Before") else t("Nachher","After"),style=MaterialTheme.typography.titleLarge)}
                items((0..8).toList(),key={"reading-$stage-$it"}) {index->
                    val raw=if(stage==0)before else after
                    OutlinedTextField(raw[index],{input->val next=raw.toMutableList();next[index]=input;if(stage==0)before=next.toList() else after=next.toList()},
                        label={Text(fields[index])},enabled=!busy,modifier=Modifier.fillMaxWidth().testTag("kalte-reading-${if(stage==0)"before" else "after"}-${serviceFieldKeys[index]}"),singleLine=true,
                        keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),isError=raw[index].isNotBlank()&&raw[index].trim().replace(',','.').toDoubleOrNull()?.isFinite()!=true)
                }
            }
            item("visit-notes") {OutlinedTextField(notes,{notes=it},label={Text(t("Messquelle / Tätigkeit / Notizen","Measurement source / work / notes"))},enabled=!busy,modifier=Modifier.fillMaxWidth(),minLines=3,isError=notes.length>2000)}
            val beforeValue=serviceReading(before);val afterValue=serviceReading(after)
            item("save-visit") {
                Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                    if(beforeValue==null||afterValue==null)Text(t("Speichern erst mit vollständigen, gültigen Messwerten. Temperaturen −200…300 °C; Absolutdrücke müssen positiv sein; Luftmenge 0…100000 m³/h.","Complete valid readings are required. Temperatures −200…300 °C; absolute pressures must be positive; air volume 0…100000 m³/h."))
                    Button(onClick={
                        if(beforeValue!=null&&afterValue!=null) {
                            if(visitTime.isEmpty())visitTime=Instant.now().toString()
                            val visit=KalteVisit(visitID,asset.id,visitTime,beforeValue,afterValue,notes)
                            val next=KalteServiceRules.addVisit(current,visit)
                            save(next,current.revision){visitEditor=false;selectedVisit=visit.id}
                        }
                    },enabled=!busy&&beforeValue!=null&&afterValue!=null&&notes.length<=2000,modifier=Modifier.fillMaxWidth()){Text(t("Servicebesuch dauerhaft speichern","Save service visit"))}
                    Text(t("Zeitpunkt wird beim Speichern als UTC erfasst. Gespeicherte Messungen werden nicht nachträglich überschrieben.","The save time is recorded in UTC. Saved readings are not overwritten later."))
                }
            }
        }
    }
    if(confirmLeave)AlertDialog(onDismissRequest={confirmLeave=false},title={Text(t("Eingaben verwerfen?","Discard input?"))},text={Text(t("Nicht gespeicherte Eingaben gehen verloren. Bereits gespeicherte Besuche bleiben erhalten.","Unsaved input will be lost. Saved visits are kept."))},confirmButton={TextButton(onClick={confirmLeave=false;assetEditor=false;visitEditor=false}){Text(t("Verwerfen","Discard"))}},dismissButton={TextButton(onClick={confirmLeave=false}){Text(t("Weiter bearbeiten","Keep editing"))}})
    if(reloadConfirmation)AlertDialog(onDismissRequest={reloadConfirmation=false},title={Text(t("Gespeicherten Stand laden?","Load saved progress?"))},text={Text(t("Nicht gespeicherte Eingaben werden verworfen. Beschädigte Dateien werden nicht ersetzt.","Unsaved input will be discarded. Damaged files are not replaced."))},confirmButton={TextButton(onClick={reloadConfirmation=false;reload()}){Text(t("Laden","Load"))}},dismissButton={TextButton(onClick={reloadConfirmation=false}){Text(t("Abbrechen","Cancel"))}})
}
