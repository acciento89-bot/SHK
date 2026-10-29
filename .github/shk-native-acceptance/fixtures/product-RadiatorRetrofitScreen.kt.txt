package de.kamilunavo.shk

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import java.io.File
import java.util.Locale
import java.util.UUID

@OptIn(ExperimentalComposeUiApi::class)
@Composable
internal fun ShkDraftField(label:String,value:String,enabled:Boolean,onChange:(String)->Unit,numeric:Boolean=false,testID:String="") {
    OutlinedTextField(value,onChange,label={Text(label)},enabled=enabled,keyboardOptions=KeyboardOptions(keyboardType=if(numeric)KeyboardType.Decimal else KeyboardType.Text),modifier=if(testID.isEmpty())Modifier.fillMaxWidth()else Modifier.fillMaxWidth().testTag(testID).semantics { testTagsAsResourceId = true })
}
@Composable
fun RadiatorRetrofitScreen(onShare:(String)->Unit,onBack:()->Unit) {
    val context=LocalContext.current.applicationContext;val file=remember(context){RadiatorRetrofitFile(File(context.filesDir,"radiator-retrofit-v1.json"))}
    val state=rememberShkWorkflowStore(file,{file.load()},{book,revision->file.save(book,revision)})
    var english by rememberSaveable{mutableStateOf(!Locale.getDefault().language.startsWith("de"))};fun t(de:String,en:String)=if(english)en else de
    fun number(value:Double)=String.format(if(english)Locale.US else Locale.GERMANY,"%.1f",value)
    var projectID by rememberSaveable{mutableStateOf<String?>(null)};var roomID by rememberSaveable{mutableStateOf("")};var proposed by rememberSaveable{mutableStateOf(false)}
    var editor by rememberSaveable{mutableStateOf(0)};var editID by rememberSaveable{mutableStateOf("")};var name by rememberSaveable{mutableStateOf("")}
    var a by rememberSaveable{mutableStateOf("")};var b by rememberSaveable{mutableStateOf("")};var c by rememberSaveable{mutableStateOf("")}
    var discard by rememberSaveable{mutableStateOf(false)};var reload by rememberSaveable{mutableStateOf(false)}
    val book=state.book;val project=book?.projects?.find{it.id==projectID}
    fun leave(){if(state.busy)return;if(editor!=0)discard=true else if(projectID!=null)projectID=null else onBack()};BackHandler{leave()}
    fun begin(kind:Int){editor=kind;editID=UUID.randomUUID().toString();name="";a="";b="";c=""}
    val candidate=if(book!=null&&editor!=0)runCatching {
        when(editor){
            1->RadiatorRetrofitRules.addProject(book,editID,name.trim())
            2->{val old=project!!.rooms.find{it.id==editID};RadiatorRetrofitRules.putRoom(book,project.id,RadiatorRoom(editID,name.trim(),shkNumber(a)?:error("load"),old?.existing?:emptyList(),old?.proposed?:emptyList()))}
            3->RadiatorRetrofitRules.putScenario(book,project!!.id,RadiatorScenario(editID,name.trim(),shkNumber(a)?:error("supply"),shkNumber(b)?:error("return"),shkNumber(c)?:error("room")))
            4->{val room=project!!.rooms.single{it.id==roomID};val value=RadiatorEmitter(editID,name.trim(),shkNumber(a)?:error("nominal"),shkNumber(b)?:error("exponent"),c.trim().toIntOrNull()?:error("count"));val previous=if(proposed)room.proposed else room.existing;val changed=if(previous.any{it.id==editID})previous.map{if(it.id==editID)value else it}else previous+value;RadiatorRetrofitRules.putRoom(book,project.id,if(proposed)room.copy(proposed=changed)else room.copy(existing=changed))}
            else->error("editor")
        }
    }.getOrNull()else null
    LazyColumn(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding(),contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        if (project == null && editor == 0) {
            item("landing-workspace") { RadiatorLandingPassport(book, state.busy, english, { english = !english }, { leave() }, { begin(1) }) }
        } else {
        item("header"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
            OutlinedButton(onClick={leave()},enabled=!state.busy){Text(t("‹ Zurück","‹ Back"))};WorkflowHeading(t("RAUMPASS / MODERNISIERUNG", "ROOM PASSPORT / RETROFIT"), "HeizkörperCalc", t("Raumlast · Bestand · Vorschlag", "Room requirement · existing · proposed"))
            TextButton(onClick={english=!english}){Text(if(english)"Deutsch"else "English")}
            Text(t("Räume, Bestand und geplante Heizkörper mit eigenen Herstellerdaten vergleichen. Heizlast selbst vorgeben. Überschüsse eines Raums gleichen Fehlleistung anderer Räume nicht aus.","Compare rooms, existing and proposed radiators using your manufacturer data. Enter room heat requirements. Surplus in one room does not cancel another room's shortfall."))
        }}
        }
        if(state.busy)item("busy"){LinearProgressIndicator(Modifier.fillMaxWidth())}
        if(state.error)item("error"){Column{Text(t("Laden/Speichern fehlgeschlagen. Eingaben bleiben erhalten.","Load/save failed. Input is retained."),color=MaterialTheme.colorScheme.error);OutlinedButton(onClick={if(editor!=0)reload=true else state.reload()},enabled=!state.busy){Text(t("Gespeicherten Stand laden","Reload saved progress"))}}}
        if(book==null)item("unavailable"){Text(t("Archiv lädt oder ist gesperrt.","Archive loading or unavailable."))}
        if(book!=null&&editor==0&&project==null){
            items(book.projects,key={"project-${it.id}"}){entry->RoomPassportCover(entry.name, entry.rooms.size, entry.scenarios.size, english, !state.busy) { projectID=entry.id }}
            item("landing-notes") { Text(t("Eigene Heizlast und Herstellerdaten verwenden. Überschüsse eines Raums gleichen Fehlleistung anderer Räume nicht aus.", "Use your heat requirement and manufacturer data. A room's excess capacity does not offset another room's shortfall."), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        if(book!=null&&editor!=0)item("editor"){Column(verticalArrangement=Arrangement.spacedBy(12.dp)){
            Text(when(editor){1->t("Neues Projekt","New project");2->t("Raum und eigene Heizlast","Room and heat requirement");3->t("Temperaturalternative","Temperature alternative");else->if(proposed)t("Geplanter Heizkörper","Proposed radiator")else t("Vorhandener Heizkörper","Existing radiator")},style=MaterialTheme.typography.titleLarge)
            ShkDraftField(t("Bezeichnung","Name"),name,!state.busy,{name=it},testID="radiator-field-name")
            if(editor>=2)ShkDraftField(when(editor){2->t("Raum-Heizlast W","Room heat requirement W");3->t("Vorlauf °C","Supply °C");else->t("Hersteller-Nennleistung ΔT50 W je Stück","Manufacturer nominal ΔT50 W per unit")},a,!state.busy,{a=it},true,testID="radiator-field-a")
            if(editor>=3){ShkDraftField(if(editor==3)t("Rücklauf °C","Return °C")else t("Hersteller-Exponent n","Manufacturer exponent n"),b,!state.busy,{b=it},true,testID="radiator-field-b");ShkDraftField(if(editor==3)t("Raum °C","Room °C")else t("Anzahl (ganze Zahl)","Count (whole number)"),c,!state.busy,{c=it},true,testID="radiator-field-c")}
            if(candidate==null)Text(t("Alle Felder gültig ausfüllen. Temperatur: Vorlauf ≥ Rücklauf > Raum. Herstellerleistung/n positiv; Anzahl1–100.","Complete all fields. Temperatures: supply ≥ return > room. Manufacturer output/n positive; count1–100."))
            val creating=editor==1
            Button(onClick={candidate?.let{state.commit(it,book.revision){editor=0;if(creating)projectID=editID}}},enabled=!state.busy&&candidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Speichern","Save"))}
        }}
        if(book!=null&&project!=null&&editor==0){
            item("project"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){Text(project.name,style=MaterialTheme.typography.titleLarge);Button(onClick={begin(2)},enabled=!state.busy&&project.rooms.size<40,modifier=Modifier.fillMaxWidth()){Text(t("Raum aufnehmen","Add room"))};Button(onClick={begin(3)},enabled=!state.busy&&project.scenarios.size<6,modifier=Modifier.fillMaxWidth()){Text(t("Temperaturalternative hinzufügen","Add temperature alternative"))};OutlinedButton(onClick={onShare(RadiatorRetrofitRules.report(book,project.id,english))},modifier=Modifier.fillMaxWidth()){Text(t("Modernisierungsbericht teilen","Share retrofit report"))}}}
            items(project.rooms,key={"room-${it.id}"}){room->Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text(t("RAUM ", "ROOM ") + (project.rooms.indexOf(room) + 1).toString().padStart(2, '0') + "  /  " + room.name,style=MaterialTheme.typography.titleLarge)
                WorkflowCount(t("Heizlast des Raums", "Room heat requirement"), "${number(room.heatLoadW)} W")
                OutlinedButton(onClick={begin(2);editID=room.id;name=room.name;a=room.heatLoadW.toString()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Raum / Heizlast bearbeiten","Edit room / heat requirement"))}
                for(proposal in listOf(false,true)){
                    HorizontalDivider()
                    Text(if(proposal)t("02 / VORSCHLAG", "02 / PROPOSED")else t("01 / BESTAND", "01 / EXISTING"), style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                    (if(proposal)room.proposed else room.existing).forEach{emitter->OutlinedButton(onClick={begin(4);roomID=room.id;proposed=proposal;editID=emitter.id;name=emitter.name;a=emitter.nominalW.toString();b=emitter.exponent.toString();c=emitter.count.toString()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text("${emitter.name} · ${emitter.count} × ${number(emitter.nominalW)} W · n ${number(emitter.exponent)}")}}
                    Button(onClick={begin(4);roomID=room.id;proposed=proposal},enabled=!state.busy&&(if(proposal)room.proposed else room.existing).size<20,modifier=Modifier.fillMaxWidth()){Text(if(proposal)t("Vorschlagsheizkörper ergänzen","Add proposed radiator")else t("Bestandsheizkörper ergänzen","Add existing radiator"))}
                }
            }}}
            items(project.scenarios,key={"scenario-${it.id}"}){scenario->val totals=RadiatorRetrofitRules.summary(project,scenario.id);Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text("${scenario.name} · ${number(scenario.supplyC)} / ${number(scenario.returnC)} / ${number(scenario.roomC)} °C",style=MaterialTheme.typography.titleMedium)
                Text(t("Leistung Bestand / Vorschlag","Capacity existing / proposed")+": ${number(totals.existingW)} / ${number(totals.proposedW)} W")
                Text(t("Summe raumweiser Fehlleistung","Sum of room shortfalls")+": ${number(totals.existingShortfallW)} / ${number(totals.proposedShortfallW)} W")
                totals.rooms.forEach{Text(it.name+" · "+t("Fehlleistung B/V ","Shortfall E/P ")+"${number(it.existingShortfallW)} / ${number(it.proposedShortfallW)} W")}
                OutlinedButton(onClick={begin(3);editID=scenario.id;name=scenario.name;a=scenario.supplyC.toString();b=scenario.returnC.toString();c=scenario.roomC.toString()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Temperaturen bearbeiten","Edit temperatures"))}
            }}}
        }
    }
    if(discard)AlertDialog(onDismissRequest={discard=false},title={Text(t("Eingaben verwerfen?","Discard input?"))},confirmButton={TextButton(onClick={discard=false;editor=0}){Text(t("Verwerfen","Discard"))}},dismissButton={TextButton(onClick={discard=false}){Text(t("Weiter bearbeiten","Keep editing"))}})
    if(reload)AlertDialog(onDismissRequest={reload=false},title={Text(t("Eingaben verwerfen und neu laden?","Discard input and reload?"))},confirmButton={TextButton(onClick={reload=false;state.reload{editor=0}}){Text(t("Laden","Reload"))}},dismissButton={TextButton(onClick={reload=false}){Text(t("Abbrechen","Cancel"))}})
}
