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
import java.time.Instant
import java.util.Locale
import java.util.UUID

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun VentCommissioningScreen(onShare:(String)->Unit,onBack:()->Unit) {
    val context=LocalContext.current.applicationContext
    val file=remember(context){VentCommissioningFile(File(context.filesDir,"vent-commissioning-v1.json"))}
    val state=rememberShkWorkflowStore(file,{file.load()},{book,revision->file.save(book,revision)})
    var english by rememberSaveable{mutableStateOf(!Locale.getDefault().language.startsWith("de"))}
    fun t(de:String,en:String)=if(english)en else de
    fun number(value:Double?)=value?.let{String.format(if(english)Locale.US else Locale.GERMANY,"%.2f",it)}?:t("Nicht gemessen","Unmeasured")
    var projectID by rememberSaveable{mutableStateOf<String?>(null)}
    var editor by rememberSaveable{mutableStateOf(0)}
    var editID by rememberSaveable{mutableStateOf("")}
    var name by rememberSaveable{mutableStateOf("")}
    var roomID by rememberSaveable{mutableStateOf("")}
    var side by rememberSaveable{mutableStateOf("SUPPLY")}
    var target by rememberSaveable{mutableStateOf("")}
    var measured by rememberSaveable{mutableStateOf("")}
    var note by rememberSaveable{mutableStateOf("")}
    var visitTime by rememberSaveable{mutableStateOf("")}
    var expandedVisit by rememberSaveable{mutableStateOf<String?>(null)}
    var discard by rememberSaveable{mutableStateOf(false)}
    var reload by rememberSaveable{mutableStateOf(false)}
    var deleteID by rememberSaveable{mutableStateOf<String?>(null)}
    var deleteRoom by rememberSaveable{mutableStateOf(false)}
    val book=state.book;val project=book?.projects?.find{it.id==projectID}
    fun leave(){if(state.busy)return;if(editor!=0)discard=true else if(projectID!=null)projectID=null else onBack()}
    BackHandler{leave()}
    fun begin(kind:Int){editor=kind;editID=UUID.randomUUID().toString();name="";note="";visitTime="";target="";measured="";roomID=project?.rooms?.firstOrNull()?.id.orEmpty();side="SUPPLY"}
    fun commit(next:VentCommissioningBook,done:()->Unit={}) {if(book!=null)state.commit(next,book.revision){editor=0;done()}}
    val terminal=if(editor==3&&project!=null)runCatching {VentTerminal(editID,roomID,name.trim(),VentSide.valueOf(side),shkNumber(target)?:error("target"),if(measured.isBlank())null else shkNumber(measured)?:error("measured"))}.getOrNull()else null
    val terminalCandidate=if(terminal!=null&&book!=null)runCatching{VentCommissioningRules.putTerminal(book,project!!.id,terminal)}.getOrNull()else null
    LazyColumn(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding().semantics { testTagsAsResourceId = true },contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(14.dp)) {
        if (project == null && editor == 0) {
            item("landing-workspace") { VentLandingBoard(book, state.busy, english, { english = !english }, { leave() }, { begin(1) }) }
        } else {
        item("header") {
            Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick={leave()},enabled=!state.busy){Text(t("‹ Zurück","‹ Back"))}
                WorkflowHeading(t("INBETRIEBNAHME / RAUMREGISTER", "COMMISSIONING / ROOM REGISTER"), "LüftungsCalc", t("Räume  →  Ventile  →  Einstellbesuche", "Rooms  →  terminals  →  adjustment visits"))
                TextButton(onClick={english=!english}){Text(if(english)"Deutsch" else "English")}
                Text(t("Soll- und Ist-Luftmengen je Ventil. Zuluft und Abluft bleiben getrennt. Einstellbesuche behalten ihre ursprünglichen Räume und Messwerte.","Target and measured flow per terminal. Supply and extract stay separate. Adjustment visits keep their original rooms and readings."))
            }
        }
        }
        if(state.busy)item("busy"){LinearProgressIndicator(Modifier.fillMaxWidth())}
        if(state.error)item("error") {Column {Text(t("Laden oder Speichern fehlgeschlagen. Eingaben und vorhandene Daten bleiben erhalten.","Loading or saving failed. Input and existing data are kept."),color=MaterialTheme.colorScheme.error);OutlinedButton(onClick={if(editor!=0)reload=true else state.reload()},enabled=!state.busy){Text(t("Gespeicherten Stand laden","Load saved progress"))}}}
        if(book==null)item("loading"){Text(t("Projektarchiv wird geladen oder ist gesperrt.","Project archive is loading or unavailable."))}
        if(book!=null&&project==null&&editor==0) {
            items(book.projects,key={"project-${it.id}"}) {entry->VentProjectBoard(entry.name, entry.rooms.size, entry.terminals.size, english, !state.busy) { projectID=entry.id }}
            item("landing-notes") { Text(t("Soll und Ist bleiben getrennt. Einstellbesuche behalten ihre ursprünglichen Räume und Messwerte.", "Targets and measurements stay separate. Adjustment visits keep their original rooms and readings."), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
        }
        if(book!=null&&(editor==1||editor==2)) {
            item("name-form") {Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
                Text(if(editor==1)t("Neues Projekt","New project")else t("Raum","Room"),style=MaterialTheme.typography.titleLarge)
                OutlinedTextField(name,{name=it},label={Text(t("Bezeichnung","Name"))},enabled=!state.busy,modifier=Modifier.fillMaxWidth().testTag("vent-field-name"))
                val candidate=runCatching{if(editor==1)VentCommissioningRules.addProject(book,editID,name.trim())else VentCommissioningRules.putRoom(book,project!!.id,VentRoom(editID,name.trim()))}.getOrNull()
                val creating=editor==1
                Button(onClick={if(candidate!=null)commit(candidate){if(creating)projectID=editID}},enabled=!state.busy&&candidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Speichern","Save"))}
            }}
        }
        if(book!=null&&project!=null&&editor==0) {
            item("project-heading"){Text(project.name,style=MaterialTheme.typography.titleLarge)}
            item("totals") {Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                for(direction in VentSide.entries) {
                    val total=VentCommissioningRules.totals(project.terminals,direction)
                    WorkflowCount((if(direction==VentSide.SUPPLY)t("ZULUFT", "SUPPLY")else t("ABLUFT", "EXTRACT"))+" · "+t("Soll / Ist / Δ", "Target / Measured / Δ"), "${number(total.targetM3H)} / ${number(total.measuredM3H)} / ${number(total.deviationM3H)} m³/h")
                    Text(if(total.terminalCount==0)t("Keine Messstellen erfasst","No terminals recorded")else if(total.measuredM3H==null)t("Unvollständig · ${total.unmeasuredCount} Messpunkte offen","Incomplete · ${total.unmeasuredCount} unmeasured terminals")else total.deviationPercent?.let{number(it)+"%"}?:t("Prozentabweichung nicht verfügbar","Percentage deviation unavailable"))
                }
                OutlinedButton(onClick={onShare(VentCommissioningRules.report(book,project.id,english))},modifier=Modifier.fillMaxWidth()){Text(t("Inbetriebnahmebericht teilen","Share commissioning report"))}
            }}
            item("actions") {Column(verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Button(onClick={begin(2)},enabled=!state.busy&&project.rooms.size<40,modifier=Modifier.fillMaxWidth()){Text(t("Raum hinzufügen","Add room"))}
                Button(onClick={begin(3)},enabled=!state.busy&&project.rooms.isNotEmpty()&&project.terminals.size<80,modifier=Modifier.fillMaxWidth()){Text(t("Ventil hinzufügen","Add terminal"))}
                Button(onClick={begin(4)},enabled=!state.busy&&project.terminals.isNotEmpty()&&project.visits.size<40,modifier=Modifier.fillMaxWidth()){Text(t("Einstellbesuch als Momentaufnahme speichern","Save adjustment visit snapshot"))}
            }}
            items(project.rooms,key={"room-${it.id}"}) {room->Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Text(t("RAUM ", "ROOM ") + (project.rooms.indexOf(room) + 1).toString().padStart(2, '0') + "  /  " + room.name,style=MaterialTheme.typography.titleLarge)
                for(direction in VentSide.entries) {val total=VentCommissioningRules.totals(project.terminals.filter{it.roomID==room.id},direction);Text((if(direction==VentSide.SUPPLY)t("Zuluft","Supply")else t("Abluft","Extract"))+": ${number(total.targetM3H)} / ${number(total.measuredM3H)} m³/h")}
                OutlinedButton(onClick={editor=2;editID=room.id;name=room.name},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Raum umbenennen","Rename room"))}
                OutlinedButton(onClick={deleteID=room.id;deleteRoom=true},enabled=!state.busy&&project.terminals.none{it.roomID==room.id},modifier=Modifier.fillMaxWidth()){Text(t("Leeren Raum entfernen","Remove empty room"))}
            }}}
            items(project.terminals,key={"terminal-${it.id}"}) {entry->Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Text(entry.name+" · "+project.rooms.single{it.id==entry.roomID}.name)
                Text((if(entry.side==VentSide.SUPPLY)t("Zuluft","Supply")else t("Abluft","Extract"))+" · "+t("Soll / Ist","Target / Measured")+": ${number(entry.targetM3H)} / ${number(entry.measuredM3H)} m³/h")
                OutlinedButton(onClick={editor=3;editID=entry.id;name=entry.name;roomID=entry.roomID;side=entry.side.name;target=entry.targetM3H.toString();measured=entry.measuredM3H?.toString().orEmpty()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Einstellung bearbeiten","Edit adjustment"))}
                OutlinedButton(onClick={deleteID=entry.id;deleteRoom=false},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Ventil aus aktuellem Stand entfernen","Remove current terminal"))}
            }}}
            items(project.visits.sortedByDescending{Instant.parse(it.recordedAt)},key={"visit-${it.id}"}) {visit->Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)) {
                Text(visit.recordedAt+" UTC · "+visit.note)
                OutlinedButton(onClick={expandedVisit=if(expandedVisit==visit.id)null else visit.id},modifier=Modifier.fillMaxWidth()){Text(t("Gespeicherte Messwerte anzeigen","Show saved readings"))}
                if(expandedVisit==visit.id) {
                    Text(t("Unveränderter Einstellbesuch","Unchanged adjustment visit"))
                    visit.rooms.forEach {room->Text(room.name);visit.terminals.filter{it.roomID==room.id}.forEach{entry->Text(entry.name+" · "+(if(entry.side==VentSide.SUPPLY)t("Zuluft","Supply")else t("Abluft","Extract"))+" · ${number(entry.targetM3H)} / ${number(entry.measuredM3H)} m³/h")}}
                }
            }}}
        }
        if(book!=null&&project!=null&&editor==3) {
            item("terminal-form") {Column(verticalArrangement=Arrangement.spacedBy(10.dp)) {
                Text(t("Ventil / Messstelle","Terminal / measurement point"),style=MaterialTheme.typography.titleLarge)
                OutlinedTextField(name,{name=it},label={Text(t("Bezeichnung","Name"))},enabled=!state.busy,modifier=Modifier.fillMaxWidth().testTag("vent-field-name"))
                Text(t("Raum auswählen","Choose room"));project.rooms.forEach{room->OutlinedButton(onClick={roomID=room.id},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text((if(roomID==room.id)"✓ " else "")+room.name)}}
                for(direction in VentSide.entries)OutlinedButton(onClick={side=direction.name},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text((if(side==direction.name)"✓ "else "")+(if(direction==VentSide.SUPPLY)t("Zuluft","Supply")else t("Abluft","Extract")))}
                OutlinedTextField(target,{target=it},label={Text(t("Soll m³/h","Target m³/h"))},enabled=!state.busy,keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.fillMaxWidth().testTag("vent-field-target"))
                OutlinedTextField(measured,{measured=it},label={Text(t("Ist m³/h","Measured m³/h"))},enabled=!state.busy,keyboardOptions=KeyboardOptions(keyboardType=KeyboardType.Decimal),modifier=Modifier.fillMaxWidth().testTag("vent-field-measured"))
                Text(t("Ist leer lassen, solange noch nicht gemessen wurde. 0 nur für einen tatsächlich gemessenen Nullwert eingeben.","Leave measured flow blank until measured. Enter 0 only for an actual zero reading."))
                if(terminalCandidate==null)Text(t("Name, Raum und Soll 0…100000 m³/h eingeben; Ist optional im gleichen Bereich. Bei Soll0 ist die Prozentabweichung nicht definiert.","Enter name, room and target 0…100000 m³/h; measured flow is optional in the same range. Percentage deviation is undefined for target0."))
                Button(onClick={terminalCandidate?.let{commit(it)}},enabled=!state.busy&&terminalCandidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Einstellung speichern","Save adjustment"))}
            }}
        }
        if(book!=null&&project!=null&&editor==4) {
            item("snapshot-form") {Column(verticalArrangement=Arrangement.spacedBy(12.dp)) {
                Text(t("Aktuelle Einstellungen dauerhaft dokumentieren","Document current adjustments"),style=MaterialTheme.typography.titleLarge)
                Text(t("Alle aktuellen Raumbezeichnungen, Ventile, Soll- und Istwerte werden als unveränderter Besuch gespeichert.","All current room names, terminals, target and measured values are saved as an unchanged visit."))
                OutlinedTextField(note,{note=it},label={Text(t("Tätigkeit / Messquelle / Notiz","Work / measurement source / note"))},enabled=!state.busy,modifier=Modifier.fillMaxWidth().testTag("vent-field-note"),minLines=3)
                Button(onClick={if(visitTime.isEmpty())visitTime=Instant.now().toString();commit(VentCommissioningRules.recordVisit(book,project.id,editID,visitTime,note))},enabled=!state.busy&&note.length<=2000,modifier=Modifier.fillMaxWidth()){Text(t("Einstellbesuch speichern","Save adjustment visit"))}
            }}
        }
    }
    if(discard)AlertDialog(onDismissRequest={discard=false},title={Text(t("Eingaben verwerfen?","Discard input?"))},confirmButton={TextButton(onClick={discard=false;editor=0}){Text(t("Verwerfen","Discard"))}},dismissButton={TextButton(onClick={discard=false}){Text(t("Weiter bearbeiten","Keep editing"))}})
    if(reload)AlertDialog(onDismissRequest={reload=false},title={Text(t("Nicht gespeicherte Eingaben verwerfen und laden?","Discard unsaved input and reload?"))},confirmButton={TextButton(onClick={reload=false;state.reload{editor=0}}){Text(t("Laden","Reload"))}},dismissButton={TextButton(onClick={reload=false}){Text(t("Abbrechen","Cancel"))}})
    if(deleteID!=null&&book!=null&&project!=null)AlertDialog(onDismissRequest={deleteID=null},title={Text(t("Aus aktuellem Stand entfernen?","Remove from current adjustment?"))},text={Text(t("Gespeicherte Einstellbesuche bleiben unverändert.","Saved adjustment visits stay unchanged."))},confirmButton={TextButton(onClick={val next=if(deleteRoom)VentCommissioningRules.removeRoom(book,project.id,deleteID!!)else VentCommissioningRules.removeTerminal(book,project.id,deleteID!!);deleteID=null;commit(next)}){Text(t("Entfernen","Remove"))}},dismissButton={TextButton(onClick={deleteID=null}){Text(t("Abbrechen","Cancel"))}})
}
