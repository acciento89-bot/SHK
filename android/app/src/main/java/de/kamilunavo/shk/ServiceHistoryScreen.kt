package de.kamilunavo.shk

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import java.io.File
import java.time.Instant
import java.util.Locale
import java.util.UUID

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun ServiceHistoryScreen(onShare:(String)->Unit,onBack:()->Unit) {
    val context=LocalContext.current.applicationContext;val file=remember(context){ServiceHistoryFile(File(context.filesDir,"service-history-v1.json"))}
    val state=rememberShkWorkflowStore(file,{file.load()},{book,revision->file.save(book,revision)})
    var english by rememberSaveable{mutableStateOf(!Locale.getDefault().language.startsWith("de"))};fun t(de:String,en:String)=if(english)en else de
    fun number(value:Double)=String.format(if(english)Locale.US else Locale.GERMANY,"%.2f",value)
    var installationID by rememberSaveable{mutableStateOf<String?>(null)};var editor by rememberSaveable{mutableStateOf(0)};var editID by rememberSaveable{mutableStateOf("")}
    var name by rememberSaveable{mutableStateOf("")};var checklistText by rememberSaveable{mutableStateOf("")};var checklistIDs by rememberSaveable{mutableStateOf(arrayListOf<String>())}
    var templateID by rememberSaveable{mutableStateOf("")};var checked by rememberSaveable{mutableStateOf(arrayListOf<String>())};var note by rememberSaveable{mutableStateOf("")};var nextDate by rememberSaveable{mutableStateOf("")};var recordedAt by rememberSaveable{mutableStateOf("")}
    var flow by rememberSaveable{mutableStateOf("")};var ret by rememberSaveable{mutableStateOf("")};var cold by rememberSaveable{mutableStateOf("")};var hot by rememberSaveable{mutableStateOf("")};var height by rememberSaveable{mutableStateOf("")};var valve by rememberSaveable{mutableStateOf("")};var minimum by rememberSaveable{mutableStateOf("")};var maximum by rememberSaveable{mutableStateOf("")}
    var discard by rememberSaveable{mutableStateOf(false)};var reload by rememberSaveable{mutableStateOf(false)};var expanded by rememberSaveable{mutableStateOf<String?>(null)}
    val book=state.book;val installation=book?.installations?.find{it.id==installationID};val template=book?.templates?.find{it.id==templateID}
    fun leave(){if(state.busy)return;if(editor!=0)discard=true else if(installationID!=null)installationID=null else onBack()};BackHandler{leave()}
    fun begin(kind:Int){editor=kind;editID=UUID.randomUUID().toString();name="";checklistText="";checklistIDs=arrayListOf();checked=arrayListOf();note="";nextDate="";recordedAt="";flow="";ret="";cold="";hot="";height="";valve="";minimum="";maximum="";templateID=book?.templates?.firstOrNull()?.id.orEmpty()}
    val candidate=if(book!=null&&editor!=0)runCatching{when(editor){
        1->ServiceHistoryRules.addInstallation(book,ServiceInstallation(editID,name.trim()))
        2->{val labels=checklistText.split('\n').map{it.trim()};require(labels.size<=30&&labels.all{it.isNotEmpty()});require(checklistIDs.size>=labels.size);val items=labels.mapIndexed{i,label->ServiceChecklistItem(checklistIDs[i],label)};if(book.templates.any{it.id==editID})ServiceHistoryRules.reviseTemplate(book,editID,name.trim(),items)else ServiceHistoryRules.addTemplate(book,ServiceTemplate(editID,name.trim(),1,items))}
        3->{require(recordedAt.isNotEmpty());ServiceHistoryRules.addVisit(book,ServiceVisit(editID,installation!!.id,recordedAt,ServiceMeasurements(shkNumber(flow)?:error("flow"),shkNumber(ret)?:error("return"),shkNumber(cold)?:error("cold"),shkNumber(hot)?:error("hot"),shkNumber(height)?:error("height"),shkNumber(valve)?:error("valve")),ServiceLimits(shkNumber(minimum)?:error("minimum"),shkNumber(maximum)?:error("maximum")),template?:error("checklist"),checked.toList(),note,nextDate.trim().takeIf{it.isNotEmpty()}))}
        else->error("editor")
    }}.getOrNull()else null
    LazyColumn(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding(),contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item("header"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
            OutlinedButton(onClick={leave()},enabled=!state.busy){Text(t("‹ Zurück","‹ Back"))};Text(t("AnlagenCheck · Servicehistorie","AnlagenCheck · Service history"),style=MaterialTheme.typography.headlineMedium);TextButton(onClick={english=!english}){Text(if(english)"Deutsch"else "English")}
            Text(t("Wiederkehrende Besuche mit versionierten eigenen Checklisten, Messwerten und lokalen Folgeterminen dokumentieren. Keine Sicherheitsfreigabe und keine Systembenachrichtigung.","Document repeat visits with versioned user checklists, measurements and local next-service dates. No safety approval or system notification."))
        }}
        if(state.busy)item("busy"){LinearProgressIndicator(Modifier.fillMaxWidth())}
        if(state.error)item("error"){Column{Text(t("Laden/Speichern fehlgeschlagen. Eingaben bleiben erhalten.","Load/save failed. Input is retained."),color=MaterialTheme.colorScheme.error);OutlinedButton(onClick={if(editor!=0)reload=true else state.reload()},enabled=!state.busy){Text(t("Gespeicherten Stand laden","Reload saved progress"))}}}
        if(book==null)item("unavailable"){Text(t("Archiv lädt oder ist gesperrt.","Archive loading or unavailable."))}
        if(book!=null&&editor==0&&installation==null){
            item("actions"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){Button(onClick={begin(1)},enabled=!state.busy&&book.installations.size<40,modifier=Modifier.fillMaxWidth()){Text(t("Anlage anlegen","Add installation"))};Button(onClick={begin(2)},enabled=!state.busy&&book.templates.size<30,modifier=Modifier.fillMaxWidth()){Text(t("Eigene Checkliste anlegen","Create own checklist"))}}}
            items(book.installations,key={"installation-${it.id}"}){entry->OutlinedButton(onClick={installationID=entry.id},modifier=Modifier.fillMaxWidth()){Text(entry.name+" · "+book.visits.count{it.installationID==entry.id}+t(" Besuche"," visits"))}}
            item("agenda"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){Text(t("Lokale nächste Services","Local next services"),style=MaterialTheme.typography.titleLarge);val due=ServiceHistoryRules.nextServices(book);if(due.isEmpty())Text(t("Keine Folgetermine gespeichert.","No next-service dates saved."));due.forEach{Text(it.date+" · "+it.name)}}}
            items(book.templates,key={"template-${it.id}"}){entry->OutlinedButton(onClick={begin(2);editID=entry.id;name=entry.name;checklistText=entry.items.joinToString("\n"){it.label};checklistIDs=ArrayList(entry.items.map{it.id})},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(entry.name+" · v${entry.version} · "+t("Neue Version bearbeiten","Edit new version"))}}
        }
        if(book!=null&&editor in 1..2)item("name-form"){Column(verticalArrangement=Arrangement.spacedBy(12.dp)){
            Text(if(editor==1)t("Anlage","Installation")else t("Eigene Checkliste · eine Prüffrage pro Zeile","Own checklist · one item per line"),style=MaterialTheme.typography.titleLarge)
            ShkDraftField(t("Bezeichnung","Name"),name,!state.busy,{name=it},testID="service-field-name")
            if(editor==2){OutlinedTextField(checklistText,{raw->checklistText=raw;val count=raw.split('\n').size;val ids=ArrayList(checklistIDs);while(ids.size<count&&ids.size<30)ids.add(UUID.randomUUID().toString());checklistIDs=ids},label={Text(t("Prüffragen (1–30)","Checklist items (1–30)"))},minLines=4,enabled=!state.busy,modifier=Modifier.fillMaxWidth().testTag("service-field-checklist").semantics { testTagsAsResourceId = true });Text(t("Speichern erzeugt eine neue Version. Frühere Besuche bleiben unverändert.","Saving creates a new version. Previous visits remain unchanged."))}
            if(candidate==null)Text(t("Bezeichnung und alle Prüffragen vollständig eingeben (je höchstens120 Zeichen).","Complete the name and every checklist item (at most120 characters each)."))
            val creating=editor==1
            Button(onClick={candidate?.let{state.commit(it,book.revision){editor=0;if(creating)installationID=editID}}},enabled=!state.busy&&candidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Speichern","Save"))}
        }}
        if(book!=null&&installation!=null&&editor==0){
            item("installation"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text(installation.name,style=MaterialTheme.typography.titleLarge)
                Button(onClick={begin(3);recordedAt=Instant.now().toString()},enabled=!state.busy&&book.templates.isNotEmpty()&&book.visits.size<400,modifier=Modifier.fillMaxWidth()){Text(t("Servicebesuch aufnehmen","Record service visit"))}
                if(book.templates.isEmpty())Text(t("Zuerst in der Übersicht eine eigene Checkliste anlegen.","First create your own checklist on the overview."))
                OutlinedButton(onClick={onShare(ServiceHistoryRules.report(book,installation.id,english))},modifier=Modifier.fillMaxWidth()){Text(t("Servicehistorie teilen","Share service history"))}
            }}
            items(book.visits.filter{it.installationID==installation.id}.sortedByDescending{Instant.parse(it.recordedAt)},key={"visit-${it.id}"}){visit->val result=ServiceHistoryRules.values(visit.measurements,visit.limits);Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text(visit.recordedAt+" UTC",style=MaterialTheme.typography.titleMedium);Text(visit.template.name+" · v${visit.template.version} · ${visit.checked.size}/${visit.template.items.size}")
                Text("${number(result.spreadK)} K · ${number(result.pressureRiseBar)} bar · ${result.warningCount} "+t("Prüfhinweise","measurement warnings"));Text(t("Folgetermin: ","Next date: ")+(visit.nextServiceDate?:"—"))
                OutlinedButton(onClick={expanded=if(expanded==visit.id)null else visit.id},modifier=Modifier.fillMaxWidth()){Text(t("Gespeicherte Prüfdaten anzeigen","Show saved inspection data"))}
                if(expanded==visit.id){val m=visit.measurements;Text(t("Vorlauf / Rücklauf: ","Supply / return: ")+"${number(m.flowC)} / ${number(m.returnC)} °C");Text(t("Kalt / Warm: ","Cold / hot: ")+"${number(m.coldBar)} / ${number(m.hotBar)} bar");Text(t("Höhe / Sicherheitsventil: ","Height / safety valve: ")+"${number(m.staticHeightM)} m / ${number(m.safetyValveBar)} bar");Text(t("Eigene Druckgrenzen: ","User pressure limits: ")+"${number(visit.limits.minColdBar)} / ${number(visit.limits.maxColdBar)} bar");visit.template.items.forEach{Text((if(it.id in visit.checked)"[x] "else "[ ] ")+it.label)};Text(visit.notes)}
            }}}
        }
        if(book!=null&&installation!=null&&editor==3)item("visit-form"){Column(verticalArrangement=Arrangement.spacedBy(12.dp)){
            Text(t("Servicebesuch · eigene Messungen","Service visit · own readings"),style=MaterialTheme.typography.titleLarge);Text(recordedAt+" UTC")
            book.templates.forEach{entry->OutlinedButton(onClick={templateID=entry.id;checked=arrayListOf()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text((if(templateID==entry.id)"✓ "else "")+entry.name+" · v${entry.version}")}}
            template?.items?.forEach{item->Row(Modifier.fillMaxWidth()){Checkbox(item.id in checked,{on->checked=ArrayList(if(on)checked+item.id else checked.filter{it!=item.id})},enabled=!state.busy);Text(item.label,modifier=Modifier.weight(1f).padding(top=12.dp))}}
            ShkDraftField(t("Vorlauf °C","Supply °C"),flow,!state.busy,{flow=it},true,testID="service-field-flow");ShkDraftField(t("Rücklauf °C","Return °C"),ret,!state.busy,{ret=it},true,testID="service-field-return")
            ShkDraftField(t("Kaltfülldruck bar","Cold pressure bar"),cold,!state.busy,{cold=it},true,testID="service-field-cold");ShkDraftField(t("Warmdruck bar","Hot pressure bar"),hot,!state.busy,{hot=it},true,testID="service-field-hot")
            ShkDraftField(t("Statische Höhe m","Static height m"),height,!state.busy,{height=it},true,testID="service-field-height");ShkDraftField(t("Sicherheitsventil bar","Safety valve bar"),valve,!state.busy,{valve=it},true,testID="service-field-valve")
            ShkDraftField(t("Eigener Kaltfülldruck min. bar","Own cold pressure min. bar"),minimum,!state.busy,{minimum=it},true,testID="service-field-minimum");ShkDraftField(t("Eigener Kaltfülldruck max. bar","Own cold pressure max. bar"),maximum,!state.busy,{maximum=it},true,testID="service-field-maximum")
            OutlinedTextField(note,{note=it},label={Text(t("Tätigkeit / Messquelle / Notiz (max.2000)","Work / measurement source / note (max.2000)"))},minLines=3,enabled=!state.busy,modifier=Modifier.fillMaxWidth().testTag("service-field-note").semantics { testTagsAsResourceId = true })
            ShkDraftField(t("Nächster Service YYYY-MM-DD (optional)","Next service YYYY-MM-DD (optional)"),nextDate,!state.busy,{nextDate=it},testID="service-field-date")
            if(candidate==null)Text(t("Alle Messwerte und eigene Druckgrenzen gültig eingeben; Folgetermin frühestens Besuchsdatum. Ungeprüfte Punkte bleiben ausdrücklich offen.","Enter valid readings and own pressure limits; next date cannot precede this visit. Unchecked items remain explicitly open."))
            Button(onClick={candidate?.let{state.commit(it,book.revision){editor=0}}},enabled=!state.busy&&candidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Besuch unverändert speichern","Save visit snapshot"))}
        }}
    }
    if(discard)AlertDialog(onDismissRequest={discard=false},title={Text(t("Eingaben verwerfen?","Discard input?"))},confirmButton={TextButton(onClick={discard=false;editor=0}){Text(t("Verwerfen","Discard"))}},dismissButton={TextButton(onClick={discard=false}){Text(t("Weiter bearbeiten","Keep editing"))}})
    if(reload)AlertDialog(onDismissRequest={reload=false},title={Text(t("Eingaben verwerfen und neu laden?","Discard input and reload?"))},confirmButton={TextButton(onClick={reload=false;state.reload{editor=0}}){Text(t("Laden","Reload"))}},dismissButton={TextButton(onClick={reload=false}){Text(t("Abbrechen","Cancel"))}})
}
