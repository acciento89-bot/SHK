package de.kamilunavo.shk

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import java.io.File
import java.util.Locale
import java.util.UUID

@Composable
fun PipeCircuitScreen(onShare:(String)->Unit,onBack:()->Unit) {
    val context=LocalContext.current.applicationContext;val file=remember(context){PipeCircuitFile(File(context.filesDir,"pipe-circuits-v1.json"))}
    val state=rememberShkWorkflowStore(file,{file.load()},{book,revision->file.save(book,revision)})
    var english by rememberSaveable{mutableStateOf(!Locale.getDefault().language.startsWith("de"))};fun t(de:String,en:String)=if(english)en else de
    fun number(value:Double)=String.format(if(english)Locale.US else Locale.GERMANY,"%.3f",value)
    var projectID by rememberSaveable{mutableStateOf<String?>(null)};var pathID by rememberSaveable{mutableStateOf<String?>(null)};var proposal by rememberSaveable{mutableStateOf(false)}
    var editor by rememberSaveable{mutableStateOf(0)};var editID by rememberSaveable{mutableStateOf("")};var name by rememberSaveable{mutableStateOf("")}
    var a by rememberSaveable{mutableStateOf("")};var b by rememberSaveable{mutableStateOf("")};var c by rememberSaveable{mutableStateOf("")};var d by rememberSaveable{mutableStateOf("")}
    var discard by rememberSaveable{mutableStateOf(false)};var reload by rememberSaveable{mutableStateOf(false)}
    val book=state.book;val project=book?.projects?.find{it.id==projectID};val paths=if(proposal)project?.proposal else project?.baseline;val path=paths?.find{it.id==pathID}
    fun leave(){if(state.busy)return;if(editor!=0)discard=true else if(pathID!=null)pathID=null else if(projectID!=null)projectID=null else onBack()};BackHandler{leave()}
    fun begin(kind:Int){editor=kind;editID=UUID.randomUUID().toString();name="";a="";b="";c="";d=""}
    val candidate=if(book!=null&&editor!=0)runCatching{when(editor){
        1->PipeCircuitRules.addProject(book,editID,name.trim())
        2->{val old=paths?.find{it.id==editID};PipeCircuitRules.putPath(book,project!!.id,proposal,PipePath(editID,name.trim(),shkNumber(a)?:error("flow"),old?.segments?:emptyList()))}
        3->PipeCircuitRules.putSegment(book,project!!.id,proposal,path!!.id,PipeSegment(editID,name.trim(),shkNumber(a)?:error("length"),shkNumber(b)?:error("diameter"),shkNumber(c)?:error("roughness"),shkNumber(d)?:error("zeta")))
        else->error("editor")
    }}.getOrNull()else null
    LazyColumn(Modifier.fillMaxSize().windowInsetsPadding(WindowInsets.safeDrawing).imePadding(),contentPadding=PaddingValues(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)) {
        item("header"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
            OutlinedButton(onClick={leave()},enabled=!state.busy){Text(t("‹ Zurück","‹ Back"))};WorkflowHeading(t("ROUTENBLATT / ROHRKREIS", "ROUTE SHEET / PIPE CIRCUIT"), "RohrCalc", t("Parallele Pfade · Segmente in Reihe", "Parallel paths · segments in series"))
            TextButton(onClick={english=!english}){Text(if(english)"Deutsch"else "English")}
            Text(t("Bestand und Vorschlag aus parallelen Pfaden mit Segmenten in Reihe aufbauen. Volumenstrom je Pfad selbst vorgeben. Wasser nahe20 °C; keine Netzberechnung oder Pumpenauswahl.","Build baseline and proposal from parallel paths with segments in series. Enter flow for each path. Water near20 °C; no network solution or pump selection."))
        }}
        if(state.busy)item("busy"){LinearProgressIndicator(Modifier.fillMaxWidth())}
        if(state.error)item("error"){Column{Text(t("Laden/Speichern fehlgeschlagen. Eingaben bleiben erhalten.","Load/save failed. Input is retained."),color=MaterialTheme.colorScheme.error);OutlinedButton(onClick={if(editor!=0)reload=true else state.reload()},enabled=!state.busy){Text(t("Gespeicherten Stand laden","Reload saved progress"))}}}
        if(book==null)item("unavailable"){Text(t("Archiv lädt oder ist gesperrt.","Archive loading or unavailable."))}
        if(book!=null&&editor==0&&project==null){item("new"){Button(onClick={begin(1)},enabled=!state.busy&&book.projects.size<20,modifier=Modifier.fillMaxWidth()){Text(t("Rohrkreisprojekt anlegen","Create circuit project"))}};items(book.projects,key={"project-${it.id}"}){entry->PipeRouteCover(entry.name, entry.baseline.size, entry.proposal.size, english) { projectID=entry.id;pathID=null }}}
        if(book!=null&&editor!=0)item("editor"){Column(verticalArrangement=Arrangement.spacedBy(12.dp)){
            Text(when(editor){1->t("Neues Projekt","New project");2->t("Parallelpfad und Volumenstrom","Parallel path and flow");else->t("Rohrsegment in Reihe","Pipe segment in series")},style=MaterialTheme.typography.titleLarge)
            ShkDraftField(t("Bezeichnung","Name"),name,!state.busy,{name=it},testID="pipe-field-name")
            if(editor>=2)ShkDraftField(if(editor==2)t("Vorgegebener Volumenstrom l/h","Declared flow l/h")else t("Reale Länge m","Actual length m"),a,!state.busy,{a=it},true,testID="pipe-field-a")
            if(editor==3){ShkDraftField(t("Freier Innendurchmesser mm","Free inside diameter mm"),b,!state.busy,{b=it},true,testID="pipe-field-b");ShkDraftField(t("Rauheit mm","Roughness mm"),c,!state.busy,{c=it},true,testID="pipe-field-c");ShkDraftField(t("Summe örtlicher Widerstände ζ","Local resistance sum ζ"),d,!state.busy,{d=it},true,testID="pipe-field-d")}
            if(candidate==null)Text(t("Alle Felder gültig ausfüllen. Nichtnegative Länge, Rauheit und ζ; Innendurchmesser ≥0,1 mm. Volumenstrom0…1000000 l/h.","Complete all fields. Nonnegative length, roughness and ζ; inside diameter ≥0.1 mm. Flow0…1000000 l/h."))
            val creating=editor==1
            Button(onClick={candidate?.let{state.commit(it,book.revision){editor=0;if(creating)projectID=editID}}},enabled=!state.busy&&candidate!=null,modifier=Modifier.fillMaxWidth()){Text(t("Speichern","Save"))}
        }}
        if(book!=null&&project!=null&&editor==0&&path==null){
            item("project"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text(project.name,style=MaterialTheme.typography.titleLarge)
                for(alternative in listOf(false,true)){val total=PipeCircuitRules.summary(project,alternative);Text((if(alternative)t("Vorschlag","Proposal")else t("Bestand","Baseline"))+" · "+t("ungünstigster Pfad ","worst path ")+"${number(total.worstLossKPa)} kPa · ${number(total.volumeLitres)} l · ${number(total.declaredFlowLPH)} l/h")}
                Text(t("Parallele Druckverluste: Maximum, keine Summe. Leere Pfade sind unvollständig.","Parallel pressure loss: maximum, not sum. Empty paths are incomplete."))
                for(alternative in listOf(false,true))OutlinedButton(onClick={proposal=alternative},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text((if(proposal==alternative)"✓ "else "")+(if(alternative)t("Vorschlag bearbeiten","Edit proposal")else t("Bestand bearbeiten","Edit baseline")))}
                Button(onClick={begin(2)},enabled=!state.busy&&(paths?.size?:0)<10,modifier=Modifier.fillMaxWidth()){Text(t("Parallelpfad hinzufügen","Add parallel path"))}
                OutlinedButton(onClick={onShare(PipeCircuitRules.report(book,project.id,english))},modifier=Modifier.fillMaxWidth()){Text(t("Rohrkreisbericht teilen","Share circuit report"))}
            }}
            items(paths.orEmpty(),key={"path-${it.id}"}){entry->val result=PipeCircuitRules.summary(project,proposal).paths.single{it.pathID==entry.id};DocketEntry("P" + (paths.orEmpty().indexOf(entry) + 1).toString().padStart(2, '0'), entry.name, "${number(entry.flowLPH)} l/h · ${number(result.lossKPa)} kPa · ${entry.segments.size} "+t("Segmente", "segments")) { pathID=entry.id }}
        }
        if(book!=null&&project!=null&&path!=null&&editor==0){
            item("path"){Column(verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text((if(proposal)t("Vorschlag","Proposal")else t("Bestand","Baseline"))+" · ${path.name}",style=MaterialTheme.typography.titleLarge);Text("${number(path.flowLPH)} l/h")
                OutlinedButton(onClick={begin(2);editID=path.id;name=path.name;a=path.flowLPH.toString()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Pfad / Volumenstrom bearbeiten","Edit path / flow"))}
                Button(onClick={begin(3)},enabled=!state.busy&&path.segments.size<30,modifier=Modifier.fillMaxWidth()){Text(t("Segment in Reihe hinzufügen","Add segment in series"))}
                if(path.segments.isEmpty())Text(t("Noch keine Segmente; keine vollständige Auslegung.","No segments yet; not a complete design."))
            }}
            items(path.segments,key={"segment-${it.id}"}){piece->val result=PipeCircuitRules.segment(path.flowLPH,piece);Card(Modifier.fillMaxWidth()){Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(8.dp)){
                Text("${(path.segments.indexOf(piece) + 1).toString().padStart(2, '0')}  ──  ${piece.name}",style=MaterialTheme.typography.titleLarge);HorizontalDivider();Text("${number(piece.lengthM)} m · Øi ${number(piece.insideMM)} mm · ζ ${number(piece.zeta)}")
                WorkflowCount(t("Δp / v / Reynolds", "Δp / v / Reynolds"), "${number(result.lossKPa)} kPa · ${number(result.velocityMS)} m/s · Re ${number(result.reynolds)}")
                OutlinedButton(onClick={begin(3);editID=piece.id;name=piece.name;a=piece.lengthM.toString();b=piece.insideMM.toString();c=piece.roughnessMM.toString();d=piece.zeta.toString()},enabled=!state.busy,modifier=Modifier.fillMaxWidth()){Text(t("Segment bearbeiten","Edit segment"))}
            }}}
        }
    }
    if(discard)AlertDialog(onDismissRequest={discard=false},title={Text(t("Eingaben verwerfen?","Discard input?"))},confirmButton={TextButton(onClick={discard=false;editor=0}){Text(t("Verwerfen","Discard"))}},dismissButton={TextButton(onClick={discard=false}){Text(t("Weiter bearbeiten","Keep editing"))}})
    if(reload)AlertDialog(onDismissRequest={reload=false},title={Text(t("Eingaben verwerfen und neu laden?","Discard input and reload?"))},confirmButton={TextButton(onClick={reload=false;state.reload{editor=0}}){Text(t("Laden","Reload"))}},dismissButton={TextButton(onClick={reload=false}){Text(t("Abbrechen","Cancel"))}})
}
