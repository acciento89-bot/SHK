package de.kamilunavo.shknativeqa;

import android.content.Intent;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.view.accessibility.AccessibilityNodeInfo;
import android.view.accessibility.AccessibilityWindowInfo;
import android.content.pm.ApplicationInfo;
import android.graphics.Rect;
import android.os.Build;
import android.os.SystemClock;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.uiautomator.*;
import org.json.*;
import org.junit.*;
import org.junit.rules.TestWatcher;
import org.junit.runner.Description;
import org.junit.runner.RunWith;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.*;
import java.util.regex.Pattern;
import static org.junit.Assert.*;

/** External host. Every target-app record is created through actual installed native UI. */
@RunWith(AndroidJUnit4.class)
public final class ShkWorkflowNativeTest {
 private static final String KALTE="de.kamilunav.kaltecalc",VENT="de.kamilunavo.luftungscalc",RADIATOR="de.kamilunavo.heizkorpercalc",PIPE="de.kamilunavo.rohrcalc",SERVICE="de.kamilunavo.servicecheck";
 private static final String UNICODE="QA Überprüfung Δ Σ ✓ Ende";
 private final UiDevice device=UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
 private final android.content.Context host=InstrumentationRegistry.getInstrumentation().getTargetContext();
 private final File evidence=new File(host.getFilesDir(),"shk-native-qa");
 private String method="unknown",expectedOwner=null;
 private int traceCount=0,criticalTraceCount=0;
 private boolean postSaveTrace=false;
 private String kalteNumericStage=null;
 @Rule public final TestWatcher watcher=new TestWatcher(){
  @Override protected void starting(Description d){method=d.getMethodName();evidence.mkdirs();event("START");}
  @Override protected void succeeded(Description d){event("PASS");}
  @Override protected void failed(Throwable e,Description d){capture(method+"-FAIL");event("FAIL "+e);}
 };
 @Before public void onlyOwnedDisposableApi35()throws Exception{assertEquals(35,Build.VERSION.SDK_INT);assertEquals("Disposable emulator only","1",device.executeShellCommand("getprop ro.kernel.qemu").trim());device.setOrientationNatural();device.pressHome();android.app.UiAutomation automation=InstrumentationRegistry.getInstrumentation().getUiAutomation();AccessibilityServiceInfo info=automation.getServiceInfo();assertNotNull("Accessibility service configuration required",info);info.flags|=AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;automation.setServiceInfo(info);}
 @After public void releaseRotation()throws Exception{device.setOrientationNatural();device.unfreezeRotation();}

 @Test public void kalteBeforeAfterHistoryRotateColdReopenAndUtf8File()throws Exception{
  String name=unique("Kälte");launch(KALTE);fill("Verdampfung","Verdampfung","4");fill("Sauggas","Sauggas","11");expect("7,0 K");capture("kalte-legacy-seven-K");
  click("Servicebesuche öffnen","Open service visits");english();click("Anlage anlegen","Add appliance");fill("Anlagenbezeichnung","Appliance name",name);click("Anlage speichern","Save appliance");
  click("Neuen Vorher-/Nachher-Besuch erfassen","Record a new before/after visit");
  String[] de={"Verdampfung °C","Sauggas °C","Kondensation °C","Flüssigkeit °C","Saugdruck bar(g)","Hochdruck bar(g)","Luftvolumenstrom m³/h","Luft Eintritt °C","Luft Austritt °C"};
  String[] en={"Evaporation °C","Suction gas °C","Condensation °C","Liquid °C","Suction pressure bar(g)","Discharge pressure bar(g)","Air volume m³/h","Entering air °C","Leaving air °C"};
  clickTextOnly("Vorher","Before");fillForward(de,en,new String[]{"4","11","42","36","7.5","24","800","27","19"});
  clickTextOnly("Nachher","After");fillForward(de,en,new String[]{"4","9","42","37","7","23","800","27","18"});
  fill("Messquelle / Tätigkeit / Notizen","Measurement source / work / notes",UNICODE);rotate("kalte-unsaved-note");assertField("Messquelle / Tätigkeit / Notizen","Measurement source / work / notes",UNICODE);
  click("Servicebesuch dauerhaft speichern","Save service visit");expect("Superheat change: -2.00 K","Änderung Überhitzung: -2,00 K");expect(UNICODE);capture("kalte-before-after-detail");
  JSONObject document=archive(KALTE,"kalte-service-v1.json");JSONObject asset=named(document.getJSONArray("assets"),name);JSONArray visits=forOwner(document.getJSONArray("visits"),"assetID",asset.getString("id"));assertEquals(1,visits.length());JSONObject visit=visits.getJSONObject(0);assertEquals(11,visit.getJSONObject("before").getDouble("suctionC"),0);assertEquals(9,visit.getJSONObject("after").getDouble("suctionC"),0);save("kalte-synthetic-visit.json",visit);
  launch(KALTE);click("Servicebesuche öffnen","Open service visits");english();click(name);click("Vorher / Nachher / Änderungen","Before / after / changes");expect(UNICODE);capture("kalte-cold-reopened");
  assertEquals(visit.toString(),forOwner(archive(KALTE,"kalte-service-v1.json").getJSONArray("visits"),"assetID",asset.getString("id")).getJSONObject(0).toString());
  share(KALTE,"Gesamte Anlagenhistorie teilen","Share appliance history","kalte-report",name,UNICODE,"bar(g)");
 }

 @Test public void ventCommissioningSnapshotHistoryRotateColdReopenAndUtf8File()throws Exception{
  String name=unique("Vent"),room="QA Raum Ä",renamed="QA Raum Ä geändert";
  launch(VENT);fill("Raumlänge","Raumlänge","5");fill("Raumbreite","Raumbreite","4");fill("Raumhöhe","Raumhöhe","2.5");fill("Luftwechsel","Luftwechsel","1.5");expect("75 m³/h");capture("vent-legacy-room-airchange");
  click("Räume, Ventile und Einstellbesuche","Rooms, terminals and adjustment visits");english();click("Inbetriebnahmeprojekt anlegen","Create commissioning project");fill("Bezeichnung","Name",name);saveButton();
  click("Raum hinzufügen","Add room");fill("Bezeichnung","Name",room);rotate("vent-room-draft");assertField("Bezeichnung","Name",room);saveButton();
  terminal("QA Supply",true,"100","90");terminal("QA Extract",false,"80","75");
  snapshot("QA Visit Before "+UNICODE);cardAction(room,"Raum umbenennen","Rename room");fill("Bezeichnung","Name",renamed);saveButton();snapshot("QA Visit After "+UNICODE);
  JSONObject project=project(VENT,"vent-commissioning-v1.json",name);JSONArray visits=project.getJSONArray("visits");assertEquals(2,visits.length());assertEquals(room,visits.getJSONObject(0).getJSONArray("rooms").getJSONObject(0).getString("name"));assertEquals(renamed,visits.getJSONObject(1).getJSONArray("rooms").getJSONObject(0).getString("name"));assertEquals(2,project.getJSONArray("terminals").length());save("vent-synthetic-project.json",project);capture("vent-two-snapshots");
  launch(VENT);click("Räume, Ventile und Einstellbesuche","Rooms, terminals and adjustment visits");english();click(name);expect("QA Visit Before", "QA Visit After");assertEquals(project.toString(),project(VENT,"vent-commissioning-v1.json",name).toString());capture("vent-cold-reopened");
  share(VENT,"Inbetriebnahmebericht teilen","Share commissioning report","vent-report",name,room,renamed,"QA Supply","QA Extract",UNICODE);
 }
 private void terminal(String name,boolean supply,String target,String measured){click("Ventil hinzufügen","Add terminal");fill("Bezeichnung","Name",name);click(supply?"Zuluft":"Abluft",supply?"Supply":"Extract");fill("Soll m³/h","Target m³/h",target);fill("Ist m³/h","Measured m³/h",measured);click("Einstellung speichern","Save adjustment");}
 private void snapshot(String note){click("Einstellbesuch als Momentaufnahme speichern","Save adjustment visit snapshot");fill("Tätigkeit / Messquelle / Notiz","Work / measurement source / note",note);click("Einstellbesuch speichern","Save adjustment visit");expect(note);}

 @Test public void radiatorRetrofitBaselineProposalTemperaturesRotateColdReopenAndUtf8File()throws Exception{
  String name=unique("Radiator"),room="QA Zimmer Überprüfung";
  launch(RADIATOR);fill("Hersteller-Nennleistung ΔT50","Hersteller-Nennleistung ΔT50","2000");fill("Vorlauf","Vorlauf","75");fill("Rücklauf","Rücklauf","65");fill("Raum","Raum","20");fill("Hersteller-Exponent n","Hersteller-Exponent n","1.3");expect("2000 W");capture("radiator-legacy-deltaT50");
  click("Modernisierung · Räume & Temperaturvarianten","Retrofit · rooms & temperature alternatives");english();click("Modernisierung anlegen","Create retrofit project");fill("Bezeichnung","Name",name);saveButton();
  click("Raum aufnehmen","Add room");fill("Bezeichnung","Name",room);fill("Raum-Heizlast W","Room heat requirement W","1500");rotate("radiator-room-draft");assertField("Raum-Heizlast W","Room heat requirement W","1500");fill("Raum-Heizlast W","Room heat requirement W","");assertFalse(control(find("Speichern","Save")).isEnabled());fill("Raum-Heizlast W","Room heat requirement W","1500");saveButton();
  emitter(false,"QA Bestand Ä","1000");emitter(true,"QA Vorschlag Δ","2000");
  click("Temperaturalternative hinzufügen","Add temperature alternative");fill("Bezeichnung","Name","QA 75 65 20");fill("Vorlauf °C","Supply °C","75");fill("Rücklauf °C","Return °C","65");fill("Raum °C","Room °C","20");saveButton();expect("500.0 / 0.0 W","500,0 / 0,0 W");capture("radiator-capacity-shortfalls");
  JSONObject project=project(RADIATOR,"radiator-retrofit-v1.json",name);JSONObject savedRoom=project.getJSONArray("rooms").getJSONObject(0);assertEquals(1500,savedRoom.getDouble("heatLoadW"),0);assertEquals(1000,savedRoom.getJSONArray("existing").getJSONObject(0).getDouble("nominalW"),0);assertEquals(2000,savedRoom.getJSONArray("proposed").getJSONObject(0).getDouble("nominalW"),0);assertEquals(1,project.getJSONArray("scenarios").length());save("radiator-synthetic-project.json",project);
  launch(RADIATOR);click("Modernisierung · Räume & Temperaturvarianten","Retrofit · rooms & temperature alternatives");english();click(name);expect(room);expect("500.0 / 0.0 W","500,0 / 0,0 W");assertEquals(project.toString(),project(RADIATOR,"radiator-retrofit-v1.json",name).toString());capture("radiator-cold-reopened");
  share(RADIATOR,"Modernisierungsbericht teilen","Share retrofit report","radiator-report",name,room,"QA Bestand Ä","QA Vorschlag Δ","QA 75 65 20");
 }
 private void emitter(boolean proposed,String name,String watts){click(proposed?"Vorschlagsheizkörper ergänzen":"Bestandsheizkörper ergänzen",proposed?"Add proposed radiator":"Add existing radiator");fill("Bezeichnung","Name",name);fill("Hersteller-Nennleistung ΔT50 W je Stück","Manufacturer nominal ΔT50 W per unit",watts);fill("Hersteller-Exponent n","Manufacturer exponent n","1.3");fill("Anzahl (ganze Zahl)","Count (whole number)","1");saveButton();}

 @Test public void pipeSeriesParallelBaselineProposalRotateColdReopenAndUtf8File()throws Exception{
  String name=unique("Pipe");launch(PIPE);fill("Volumenstrom","Volumenstrom","1000");fill("Freier Innendurchmesser","Freier Innendurchmesser","20");fill("Rohrlänge","Rohrlänge","10");expect("3,14 l");capture("pipe-legacy-volume");
  click("Rohrkreise · Bestand & Vorschlag","Circuits · baseline & proposal");english();click("Rohrkreisprojekt anlegen","Create circuit project");fill("Bezeichnung","Name",name);saveButton();
  click("Bestand bearbeiten","Edit baseline");addPath("QA Baseline Ä","500");click("QA Baseline Ä");segment("QA Series1","10","20");segment("QA Series2","10","20");back();
  addPath("QA Parallel","200");click("QA Parallel");segment("QA Parallel segment","5","20");back();click("Vorschlag bearbeiten","Edit proposal");addPath("QA Proposal Δ","500");click("QA Proposal Δ");
  click("Segment in Reihe hinzufügen","Add segment in series");fill("Bezeichnung","Name","QA Proposed segment");fill("Reale Länge m","Actual length m","10");fill("Freier Innendurchmesser mm","Free inside diameter mm","25");fill("Rauheit mm","Roughness mm","0.01");fill("Summe örtlicher Widerstände ζ","Local resistance sum ζ","0");rotate("pipe-segment-draft");assertField("Freier Innendurchmesser mm","Free inside diameter mm","25");saveButton();back();expect("worst path","ungünstigster Pfad");capture("pipe-baseline-proposal");
  JSONObject project=project(PIPE,"pipe-circuits-v1.json",name);JSONArray baseline=project.getJSONArray("baseline"),proposal=project.getJSONArray("proposal");assertEquals(2,baseline.length());assertEquals(1,proposal.length());assertEquals(2,named(baseline,"QA Baseline Ä").getJSONArray("segments").length());assertEquals(25,proposal.getJSONObject(0).getJSONArray("segments").getJSONObject(0).getDouble("insideMM"),0);save("pipe-synthetic-project.json",project);
  launch(PIPE);click("Rohrkreise · Bestand & Vorschlag","Circuits · baseline & proposal");english();click(name);expect("worst path","ungünstigster Pfad");assertEquals(project.toString(),project(PIPE,"pipe-circuits-v1.json",name).toString());capture("pipe-cold-reopened");share(PIPE,"Rohrkreisbericht teilen","Share circuit report","pipe-report",name,"QA Baseline Ä","QA Parallel","QA Series2","QA Proposal Δ");
 }
 private void addPath(String name,String flow){click("Parallelpfad hinzufügen","Add parallel path");fill("Bezeichnung","Name",name);fill("Vorgegebener Volumenstrom l/h","Declared flow l/h",flow);saveButton();}
 private void segment(String name,String length,String diameter){click("Segment in Reihe hinzufügen","Add segment in series");fill("Bezeichnung","Name",name);fill("Reale Länge m","Actual length m",length);fill("Freier Innendurchmesser mm","Free inside diameter mm",diameter);fill("Rauheit mm","Roughness mm","0.01");fill("Summe örtlicher Widerstände ζ","Local resistance sum ζ","0");saveButton();}

 @Test public void serviceChecklistVersionsVisitsAgendaRotateColdReopenAndUtf8File()throws Exception{
  String name=unique("Service"),template="QA Checklist "+System.currentTimeMillis(),first="QA Dichtheit Ä",second="QA Filter Δ";
  launch(SERVICE);fill("Vorlauf","Vorlauf","55");fill("Rücklauf","Rücklauf","45");expect("10,0 K");capture("service-legacy-ten-K");
  click("Servicehistorie · eigene Checklisten & Folgetermine","Service history · own checklists & next visits");english();click("Eigene Checkliste anlegen","Create own checklist");fill("Bezeichnung","Name",template);fill("Prüffragen (1–30)","Checklist items (1–30)",first+"\n"+second);saveButton();
  click("Anlage anlegen","Add installation");fill("Bezeichnung","Name",name);saveButton();recordService(template,first,"QA Before "+UNICODE);back();
  click(template);fill("Bezeichnung","Name",template);fill("Prüffragen (1–30)","Checklist items (1–30)","QA Dichtheit neu\n"+second);saveButton();click(name);recordService(template,"QA Dichtheit neu","QA After "+UNICODE);
  JSONObject document=archive(SERVICE,"service-history-v1.json");JSONObject installation=named(document.getJSONArray("installations"),name);JSONArray visits=forOwner(document.getJSONArray("visits"),"installationID",installation.getString("id"));assertEquals(2,visits.length());assertEquals(1,visits.getJSONObject(0).getJSONObject("template").getInt("version"));assertEquals(first,visits.getJSONObject(0).getJSONObject("template").getJSONArray("items").getJSONObject(0).getString("label"));assertEquals(2,visits.getJSONObject(1).getJSONObject("template").getInt("version"));assertEquals("QA Dichtheit neu",visits.getJSONObject(1).getJSONObject("template").getJSONArray("items").getJSONObject(0).getString("label"));save("service-synthetic-visits.json",new JSONObject().put("installation",installation).put("visits",visits));capture("service-two-version-history");
  launch(SERVICE);click("Servicehistorie · eigene Checklisten & Folgetermine","Service history · own checklists & next visits");english();expect(LocalDate.now(ZoneOffset.UTC).plusDays(30).toString());click(name);cardAction(visits.getJSONObject(0).getString("recordedAt")+" UTC","Gespeicherte Prüfdaten anzeigen","Show saved inspection data");expect("QA Before");cardAction(visits.getJSONObject(1).getString("recordedAt")+" UTC","Gespeicherte Prüfdaten anzeigen","Show saved inspection data");expect("QA After");assertEquals(visits.toString(),forOwner(archive(SERVICE,"service-history-v1.json").getJSONArray("visits"),"installationID",installation.getString("id")).toString());capture("service-cold-reopened");share(SERVICE,"Servicehistorie teilen","Share service history","service-report",name,template,first,"QA Dichtheit neu",UNICODE,"No safety approval");
 }
 private void recordService(String template,String item,String note)throws Exception{
  click("Servicebesuch aufnehmen","Record service visit");click(template);check(item);fill("Vorlauf °C","Supply °C","55");fill("Rücklauf °C","Return °C","45");fill("Kaltfülldruck bar","Cold pressure bar","1.5");fill("Warmdruck bar","Hot pressure bar","1.9");fill("Statische Höhe m","Static height m","8");fill("Sicherheitsventil bar","Safety valve bar","3");fill("Eigener Kaltfülldruck min. bar","Own cold pressure min. bar","1.2");fill("Eigener Kaltfülldruck max. bar","Own cold pressure max. bar","2");fill("Tätigkeit / Messquelle / Notiz (max.2000)","Work / measurement source / note (max.2000)",note);fill("Nächster Service YYYY-MM-DD (optional)","Next service YYYY-MM-DD (optional)",LocalDate.now(ZoneOffset.UTC).plusDays(30).toString());rotate("service-unsaved-visit-"+(note.contains("Before")?"before":"after"));assertField("Tätigkeit / Messquelle / Notiz (max.2000)","Work / measurement source / note (max.2000)",note);click("Besuch unverändert speichern","Save visit snapshot");
 }

 private String unique(String kind){return "QA "+kind+" "+System.currentTimeMillis();}
 private void launch(String pkg)throws Exception{
  ApplicationInfo app=host.getPackageManager().getApplicationInfo(pkg,0);assertTrue("Only root-installed debug candidate",(app.flags&ApplicationInfo.FLAG_DEBUGGABLE)!=0);
  android.content.pm.PackageInfo info=host.getPackageManager().getPackageInfo(pkg,0);event("ACTUAL_APP "+pkg+" "+info.versionName+"("+info.getLongVersionCode()+")");
  device.executeShellCommand("am force-stop "+pkg);Intent intent=host.getPackageManager().getLaunchIntentForPackage(pkg);assertNotNull("Install exact candidate first: "+pkg,intent);intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_CLEAR_TASK);host.startActivity(intent);assertTrue(device.wait(Until.hasObject(By.pkg(pkg).depth(0)),15000));device.waitForIdle(1000);expectedOwner=pkg;requireForeground("launch");
 }
 private void english(){top();if(!nodes(false,"English").isEmpty())click("English");assertFalse("Workflow language toggle must be visible",nodes(false,"Deutsch").isEmpty());}
 private Pattern pattern(boolean contains,String...labels){StringJoiner result=new StringJoiner("|","(?:",")");for(String label:labels)result.add(Pattern.quote(label));return Pattern.compile((contains?".*":"")+result+(contains?".*":""),Pattern.DOTALL);}
 private List<UiObject2> nodes(boolean contains,String...labels){requireForeground("lookup");List<UiObject2> found=device.findObjects(By.pkg(expectedOwner).text(pattern(contains,labels)));if(found.isEmpty())found=device.findObjects(By.pkg(expectedOwner).desc(pattern(contains,labels)));return found;}
 private UiObject2 forward(String...labels){
  for(int attempt=0;attempt<22;attempt++){List<UiObject2> found=nodes(false,labels);if(found.isEmpty())found=nodes(true,labels);if(!found.isEmpty())return found.get(0);scroll(false);}
  capture(method+"-missing-forward-label");throw new AssertionError("Missing forward UI label "+Arrays.toString(labels));
 }
 private UiObject2 find(String...labels){hideKeyboard();if(postSaveTrace&&Arrays.asList(labels).contains("Record a new before/after visit")){routeTrace("new-visit-lookup-before",null,labels);postSaveTrace=false;}for(int sweep=0;sweep<2;sweep++){for(int attempt=0;attempt<18;attempt++){List<UiObject2> found=nodes(false,labels);if(found.isEmpty())found=nodes(true,labels);if(!found.isEmpty())return found.get(0);scroll(false);}top();}capture(method+"-missing-label");throw new AssertionError("Missing actual native label "+Arrays.toString(labels));}
 private UiObject2 control(UiObject2 node){for(UiObject2 parent=node;parent!=null;parent=parent.getParent())if(parent.isClickable()||"android.widget.Button".equals(parent.getClassName()))return parent;return node;}
 private UiObject2 freshClickAction(String...labels){
  // Only read-side staleness is retried. The caller performs the actual click once, outside this catch.
  long deadline=SystemClock.uptimeMillis()+2000;
  do{
   requireForeground("click-target-read");
   try{
    List<UiObject2> found=nodes(false,labels);if(found.isEmpty())found=nodes(true,labels);
    if(found.size()>1)throw new AssertionError("Ambiguous native click target: "+Arrays.toString(labels));
    if(found.size()==1){UiObject2 action=control(found.get(0));Rect bounds=action.getVisibleBounds();
     assertEquals("Native action owner",expectedOwner,action.getApplicationPackage());
     assertTrue("Action disabled: "+Arrays.toString(labels),action.isEnabled());
     if(bounds.width()>0&&bounds.height()>0)return action;
    }
   }catch(androidx.test.uiautomator.StaleObjectException invalidatedRead){/* Read-only reacquisition; never click again. */}
   if(SystemClock.uptimeMillis()>=deadline)break;SystemClock.sleep(100);
  }while(SystemClock.uptimeMillis()<=deadline);
  throw new AssertionError("Fresh native action not established: "+Arrays.toString(labels));
 }
 private void click(String...labels){hideKeyboard();find(labels);UiObject2 action=freshClickAction(labels);boolean saveAppliance=Arrays.asList(labels).contains("Save appliance");if(saveAppliance){postSaveTrace=true;routeTrace("save-before-click",action,labels);}action.click();device.waitForIdle(700);if(saveAppliance)routeTrace("save-after-existing-wait",null,labels);}
 private void clickTextOnly(String...labels){hideKeyboard();find(labels).click();device.waitForIdle(300);
  if(KALTE.equals(expectedOwner)){
   if(Arrays.asList(labels).contains("Before")||Arrays.asList(labels).contains("Vorher"))kalteNumericStage="before";
   else if(Arrays.asList(labels).contains("After")||Arrays.asList(labels).contains("Nachher"))kalteNumericStage="after";
  }
 }
 private void saveButton(){click("Speichern","Save");}
 private UiObject2 editorFrom(UiObject2 label){UiObject2 selected=null;Rect title=label.getVisibleBounds();
  for(UiObject2 current=label;current!=null;current=current.getParent()){
   if("android.widget.EditText".equals(current.getClassName())){selected=current;break;}
   List<UiObject2> fields=current.findObjects(By.clazz("android.widget.EditText"));
   if(fields.size()==1){selected=fields.get(0);break;}
   // Actual Compose XML flattens MetricField rows into sibling labels/editors inside a multi-field card.
   // Match the one right-hand editor spanning this label's vertical centre, never an arbitrary card index.
   List<UiObject2> aligned=new ArrayList<>();
   for(UiObject2 field:fields){Rect bounds=field.getVisibleBounds();if(field.isEnabled()&&bounds.width()>0&&bounds.height()>0&&bounds.left>=title.right&&bounds.top<=title.centerY()&&bounds.bottom>=title.centerY())aligned.add(field);}
   if(aligned.size()==1){selected=aligned.get(0);break;}
   if(aligned.size()>1)throw new AssertionError("Ambiguous same-row editors for "+label.getText()+" "+title);
  }
  if(selected==null)throw new AssertionError("No structurally associated editor for "+label.getText()+" "+title);
  requireForeground("editor-before-focus");String owner=selected.getApplicationPackage();assertEquals("Editor must belong to expected app",expectedOwner,owner);selected.click();
  UiObject2 focused=device.wait(Until.findObject(By.pkg(owner).clazz("android.widget.EditText").focused(true)),2000);
  if(focused==null||!selected.isFocused())throw new AssertionError("Associated editor did not focus for "+label.getText());return focused;
 }
 private void fill(String de,String en,String value){if(SERVICE.equals(expectedOwner)){hideKeyboard();find(de,en);String id=ServiceFieldIdentity.id(de,en);numericTransaction().enter(id,id.startsWith("shk-metric-")?KalteNumericIdentity.legacyValue(value):value);hideKeyboard();return;}if(PIPE.equals(expectedOwner)){hideKeyboard();find(de,en);String id=PipeFieldIdentity.id(de,en);numericTransaction().enter(id,id.startsWith("shk-metric-")?KalteNumericIdentity.legacyValue(value):value);hideKeyboard();return;}if(RADIATOR.equals(expectedOwner)){hideKeyboard();find(de,en);String id=RadiatorFieldIdentity.id(de,en);numericTransaction().enter(id,id.startsWith("shk-metric-")?KalteNumericIdentity.legacyValue(value):value);hideKeyboard();return;}if(VENT.equals(expectedOwner)){hideKeyboard();find(de,en);String id=VentFieldIdentity.id(de);numericTransaction().enter(id,id.startsWith("shk-metric-")?KalteNumericIdentity.legacyValue(value):value);hideKeyboard();return;}if(KALTE.equals(expectedOwner)&&(de.equals("Verdampfung")||de.equals("Sauggas"))){hideKeyboard();String id=KalteNumericIdentity.legacyId(de);requireNumericVisible(id);numericTransaction().enter(id,KalteNumericIdentity.legacyValue(value));hideKeyboard();return;}hideKeyboard();traceWindows("fill-before-"+de,windows(),false);editorFrom(find(de,en)).setText(value);device.waitForIdle(300);requireForeground("fill-after-"+de);hideKeyboard();}
 private androidx.test.uiautomator.BySelector numericSelector(String id){
  return By.pkg(expectedOwner).clazz("android.widget.EditText").res(id);
 }
 private UiObject2 freshNumericActionNode(String label,boolean requireFocus){
  requireForeground("numeric-action");List<UiObject2> found=device.findObjects(numericSelector(label));
  if(found.size()!=1)throw new NumericInputTransaction.Failure("Exact numeric action target not unique: "+label);
  UiObject2 field=found.get(0);Rect bounds=field.getVisibleBounds();
  if(!expectedOwner.equals(field.getApplicationPackage())||!field.isEnabled()||bounds.width()<=0||bounds.height()<=0||(requireFocus&&!field.isFocused()))throw new NumericInputTransaction.Failure("Exact numeric action target not ready: "+label);
  return field; // Operation-local only: never retained across a click or write.
 }
 private NumericInputTransaction numericTransaction(){
  return new NumericInputTransaction(new NumericInputTransaction.Port(){
   public NumericInputTransaction.Snapshot observe(String label){
    requireForeground("numeric-read");
    try{
     List<UiObject2> found=device.findObjects(numericSelector(label));
     if(found.size()!=1)return new NumericInputTransaction.Snapshot(found.size(),expectedOwner,false,false,false,null);
     UiObject2 field=found.get(0);Rect bounds=field.getVisibleBounds();
     return new NumericInputTransaction.Snapshot(1,field.getApplicationPackage(),field.isEnabled(),bounds.width()>0&&bounds.height()>0,field.isFocused(),label.startsWith("shk-metric-")?KalteNumericIdentity.legacyValue(field.getText()):field.getText());
    }catch(androidx.test.uiautomator.StaleObjectException readInvalidated){throw new NumericInputTransaction.StaleRead();}
   }
   public void focus(String label){freshNumericActionNode(label,false).click();awaitNumericKeyboardReady();}
   public void write(String label,String value){
    UiObject2 target=freshNumericActionNode(label,true);
    if(label.startsWith("kalte-reading-")||VentFieldIdentity.keyboardNumeric(label)||RadiatorFieldIdentity.keyboardNumeric(label)||PipeFieldIdentity.keyboardNumeric(label)||ServiceFieldIdentity.keyboardNumeric(label)){
     String command=value.isEmpty()&&RadiatorFieldIdentity.keyboardNumeric(label)?null:KalteNumericIdentity.keyboardCommand(value);
     assertTrue("Select only the currently focused exact numeric editor",device.pressKeyCode(android.view.KeyEvent.KEYCODE_A,android.view.KeyEvent.META_CTRL_ON));
     if(command==null)assertTrue("Clear only the focused radiator numeric editor",device.pressKeyCode(android.view.KeyEvent.KEYCODE_DEL));
     else try{device.executeShellCommand(command);}catch(IOException failed){throw new NumericInputTransaction.Failure("Single controlled keyboard injection failed; not retried");}
    }else target.setText(value);
   }
   public long now(){return SystemClock.uptimeMillis();}
   public void pause(long milliseconds){SystemClock.sleep(milliseconds);}
  },expectedOwner,2000);
 }
 private void awaitNumericKeyboardReady(){
  try{InstrumentationRegistry.getInstrumentation().getUiAutomation().waitForIdle(200,2000);}
  catch(java.util.concurrent.TimeoutException notQuiet){throw new NumericInputTransaction.Failure("Numeric accessibility updates did not settle before a single write");}
  requireForeground("numeric-input-ready");
 }
 private void requireNumericVisible(String id){
  for(int attempt=0;attempt<22;attempt++){
   requireForeground("numeric-find");
   try{
    List<UiObject2> exact=device.findObjects(numericSelector(id));
    if(exact.size()>1)throw new NumericInputTransaction.Failure("Duplicate exact numeric field identity");
    if(exact.size()==1){Rect r=exact.get(0).getVisibleBounds();if(r.width()>0&&r.height()>0)return;}
    if(id.startsWith("shk-metric-")){scrollNumeric(true);continue;}
    List<String> visible=new ArrayList<>();
    for(UiObject2 field:device.findObjects(By.pkg(expectedOwner).clazz("android.widget.EditText"))){
     String resource=field.getResourceName();Rect r=field.getVisibleBounds();
     if(resource!=null&&resource.startsWith("kalte-reading-")&&r.width()>0&&r.height()>0)visible.add(resource);
    }
    int direction=KalteNumericIdentity.searchDirection(id,visible.toArray(new String[0]));
    if(direction==0){SystemClock.sleep(50);continue;}
    scrollNumeric(direction<0);
   }catch(androidx.test.uiautomator.StaleObjectException readInvalidated){SystemClock.sleep(50);}
  }
  capture(method+"-FAIL");throw new NumericInputTransaction.Failure("Required explicit stage+field ID missing: "+id);
 }
 private void scrollNumeric(boolean up){
  hideKeyboard();int[] app=requireForeground("numeric-scroll-before");List<int[]> candidates=new ArrayList<>();
  for(UiObject2 node:device.findObjects(By.pkg(expectedOwner).scrollable(true))){Rect r=node.getVisibleBounds();candidates.add(new int[]{r.left,r.top,r.right,r.bottom});}
  int[] b=NativeWindowPolicy.scrollBounds(app,candidates);if(b==null)throw new NumericInputTransaction.Failure("Numeric field not visible and no scroll container");
  int x=(b[0]+b[2])/2,center=(b[1]+b[3])/2,step=Math.max(24,(b[3]-b[1])/10);
  device.swipe(x,up?center-step:center+step,x,up?center+step:center-step,25);device.waitForIdle(300);requireForeground("numeric-scroll-after");
 }
 private void fillForward(String[] de,String[] en,String[] values){
  for(int i=0;i<values.length;i++){
   hideKeyboard();String id=KalteNumericIdentity.id(kalteNumericStage,en[i]);requireNumericVisible(id);
   numericTransaction().enter(id,values[i]);hideKeyboard();
  }
 }
 private void assertKalteRequiredValuesBeforeRotation(){
  String[] de={"Verdampfung °C","Sauggas °C","Kondensation °C","Flüssigkeit °C","Saugdruck bar(g)","Hochdruck bar(g)","Luftvolumenstrom m³/h","Luft Eintritt °C","Luft Austritt °C"};
  String[] en={"Evaporation °C","Suction gas °C","Condensation °C","Liquid °C","Suction pressure bar(g)","Discharge pressure bar(g)","Air volume m³/h","Entering air °C","Leaving air °C"};
  String[][] values={{"4","11","42","36","7.5","24","800","27","19"},{"4","9","42","37","7","23","800","27","18"}};
  top();
  for(int stage=0;stage<2;stage++){
   clickTextOnly(stage==0?"Vorher":"Nachher",stage==0?"Before":"After");
   for(int index=0;index<9;index++){String id=KalteNumericIdentity.id(kalteNumericStage,en[index]);requireNumericVisible(id);numericTransaction().verify(id,values[stage][index]);}
  }
  event("TRACE all18 required synthetic readings verified before rotation");
 }

 private void assertField(String de,String en,String expected){if(SERVICE.equals(expectedOwner)){hideKeyboard();find(de,en);numericTransaction().verify(ServiceFieldIdentity.id(de,en),expected);return;}if(PIPE.equals(expectedOwner)){hideKeyboard();find(de,en);numericTransaction().verify(PipeFieldIdentity.id(de,en),expected);return;}if(RADIATOR.equals(expectedOwner)){hideKeyboard();find(de,en);numericTransaction().verify(RadiatorFieldIdentity.id(de,en),expected);return;}if(VENT.equals(expectedOwner)){hideKeyboard();find(de,en);numericTransaction().verify(VentFieldIdentity.id(de),expected);return;}assertEquals("Visible raw draft field",expected,editorFrom(find(de,en)).getText());hideKeyboard();}
 private void cardAction(String label,String...actions){
  // A lazy card heading can be visible while its action is still below the viewport.
  // Reacquire native nodes after each owned-container scroll; never retain stale nodes.
  find(label);
  for(int step=0;step<18;step++){
   List<UiObject2> headings=nodes(false,label);
   if(headings.size()==1)for(UiObject2 parent=headings.get(0);parent!=null;parent=parent.getParent()){
    if(parent.isScrollable())break; // Never borrow a matching action from another card.
    List<UiObject2> matches=parent.findObjects(By.text(pattern(false,actions)));
    if(matches.size()==1){UiObject2 action=control(matches.get(0));Rect bounds=action.getVisibleBounds();
     if(action.isEnabled()&&bounds.width()>0&&bounds.height()>0){action.click();device.waitForIdle(700);return;}
    }
   }
   if(!scroll(false))break;
  }
  capture(method+"-missing-card-action");throw new AssertionError("No unique visible action inside card for "+label);
 }
 private UiObject2 checklistBox(String label){
  requireForeground("checklist-read");List<UiObject2> labels=nodes(false,label);
  assertEquals("Exact checklist label must be unique",1,labels.size());Rect title=labels.get(0).getVisibleBounds();
  List<UiObject2> boxes=device.findObjects(By.pkg(expectedOwner).clazz("android.widget.CheckBox"));int[][] bounds=new int[boxes.size()][];
  for(int i=0;i<boxes.size();i++){Rect b=boxes.get(i).getVisibleBounds();bounds[i]=new int[]{b.left,b.top,b.right,b.bottom};}
  UiObject2 target=boxes.get(ChecklistRowPolicy.uniqueLeftOfLabel(new int[]{title.left,title.top,title.right,title.bottom},bounds));
  assertEquals("Checkbox owner",expectedOwner,target.getApplicationPackage());assertTrue("Checkbox enabled",target.isEnabled());assertTrue("Checkbox checkable",target.isCheckable());return target;
 }
 private void check(String label){hideKeyboard();find(label);UiObject2 box=checklistBox(label);
  if(!box.isChecked())box.click(); // At most one actual action; never retry a possibly delivered click.
  device.waitForIdle(700);assertTrue("Checklist selection readback",checklistBox(label).isChecked());
 }
 private void back(){backTo(expectedOwner);}
 private void backTo(String owner){hideKeyboard();requireForeground("back-before");String previous=expectedOwner;device.pressBack();device.waitForIdle(700);expectedOwner=owner;if(!previous.equals(owner))awaitOwnerTransition(previous,owner);requireForeground("back-after");}
 private void rotate(String name)throws Exception{if(name.equals("kalte-unsaved-note"))assertKalteRequiredValuesBeforeRotation();hideKeyboard();device.setOrientationLeft();device.waitForIdle(1000);capture(name+"-landscape");device.setOrientationNatural();device.waitForIdle(1000);capture(name+"-portrait");}
 private void expect(String...fragments){for(int sweep=0;sweep<2;sweep++){for(int step=0;step<18;step++){requireForeground("expect");for(String part:fragments)if(device.hasObject(By.pkg(expectedOwner).textContains(part))||device.hasObject(By.pkg(expectedOwner).descContains(part)))return;scroll(false);}top();}capture(method+"-missing-fact");throw new AssertionError("Missing native fact "+Arrays.toString(fragments));}
 private boolean scroll(boolean up){hideKeyboard();int[] app=requireForeground("scroll-before");List<int[]> candidates=new ArrayList<>();
  for(UiObject2 node:device.findObjects(By.pkg(expectedOwner).scrollable(true))){Rect r=node.getVisibleBounds();candidates.add(new int[]{r.left,r.top,r.right,r.bottom});}
  int[] bounds=NativeWindowPolicy.scrollBounds(app,candidates);if(bounds==null)return false;traceEvent("TRACE scroll-container="+Arrays.toString(bounds),false);int x=(bounds[0]+bounds[2])/2,margin=Math.max(24,(bounds[3]-bounds[1])/5),top=bounds[1]+margin,bottom=bounds[3]-margin;
  device.swipe(x,up?top:bottom,x,up?bottom:top,25);device.waitForIdle(300);requireForeground("scroll-after");return true;
 }
 private void top(){hideKeyboard();for(int step=0;step<12;step++)if(!scroll(true))break;}
 private List<NativeWindowPolicy.Window> windows(){List<NativeWindowPolicy.Window> result=new ArrayList<>();
  for(AccessibilityWindowInfo window:InstrumentationRegistry.getInstrumentation().getUiAutomation().getWindows()){
   AccessibilityNodeInfo root=null;try{Rect bounds=new Rect();window.getBoundsInScreen(bounds);root=window.getRoot();String owner=root==null||root.getPackageName()==null?"":root.getPackageName().toString();
    result.add(new NativeWindowPolicy.Window(window.getType(),owner,window.isActive(),window.isFocused(),bounds.left,bounds.top,bounds.right,bounds.bottom));
   }finally{if(root!=null)root.recycle();window.recycle();}
  }return result;
 }
 private int[] requireForeground(String stage){List<NativeWindowPolicy.Window> current=windows();traceWindows(stage,current,false);
  try{return NativeWindowPolicy.requireApp(current,expectedOwner);}catch(AssertionError failure){traceWindows("LOST_FOREGROUND-"+stage,current,true);capture(method+"-FAIL");throw failure;}
 }
 private void traceWindows(String stage,List<NativeWindowPolicy.Window> current,boolean failure){
  StringBuilder value=new StringBuilder("TRACE ").append(stage).append(" expected=").append(expectedOwner).append(" ime=").append(NativeWindowPolicy.imeVisible(current));int count=0;
  for(NativeWindowPolicy.Window w:current){if(count++>=10)break;value.append(" | ").append(w.type).append(':').append(w.owner).append(" active=").append(w.active).append(" focused=").append(w.focused).append(" bounds=").append(Arrays.toString(w.bounds()));}
  traceEvent(value.substring(0,Math.min(value.length(),1800)),failure);
 }
 private void hideKeyboard(){List<NativeWindowPolicy.Window> before=windows();traceWindows("ime-before",before,false);NativeWindowPolicy.requireApp(before,expectedOwner);
  if(NativeWindowPolicy.imeVisible(before)){
   if(postSaveTrace)routeTrace("ime-before-existing-one-back",null);device.pressBack();long deadline=SystemClock.uptimeMillis()+3000;List<NativeWindowPolicy.Window> after;
   do{SystemClock.sleep(100);after=windows();NativeWindowPolicy.requireApp(after,expectedOwner);}while(NativeWindowPolicy.imeVisible(after)&&SystemClock.uptimeMillis()<deadline);
   traceWindows("ime-after-one-back",after,false);if(postSaveTrace)routeTrace("ime-after-existing-one-back",null);assertFalse("Actual IME must disappear after exactly one Back",NativeWindowPolicy.imeVisible(after));
  }
  requireForeground("ime-hidden");
 }
 private void traceEvent(String value,boolean critical){
  // 80 ordinary +12 critical traces; original START/ACTUAL_APP/PASS-or-FAIL remain unchanged.
  // Kälte has two launches: total<=96 JSONL entries. No extra file or raw evidence scope.
  if(critical){if(criticalTraceCount>=12)return;criticalTraceCount++;}else{if(traceCount>=80)return;traceCount++;}
  event(value.substring(0,Math.min(value.length(),1800)));
 }
 private boolean knownVisible(String...labels){return device.hasObject(By.pkg(expectedOwner).text(pattern(false,labels)));}
 private void routeTrace(String stage,UiObject2 action,String...labels){
  // Only static action labels and structural UI facts, never editor text/customer field values.
  int focused=device.findObjects(By.pkg(expectedOwner).clazz("android.widget.EditText").focused(true)).size();
  String target=action==null?"none":action.getApplicationPackage()+":"+action.getClassName()+":"+action.getVisibleBounds()+":enabled="+action.isEnabled();
  String route="ROUTE "+stage+" targetLabel="+Arrays.toString(labels)+" target="+target+" focusedEditors="+focused+
   " formSave="+knownVisible("Anlage speichern","Save appliance")+" newVisit="+knownVisible("Neuen Vorher-/Nachher-Besuch erfassen","Record a new before/after visit")+" addAppliance="+knownVisible("Anlage anlegen","Add appliance");
  traceWindows(route,windows(),true);
 }
 private JSONObject archive(String pkg,String file)throws Exception{assertTrue(file.matches("[a-z0-9-]+\\.json"));return new JSONObject(device.executeShellCommand("run-as "+pkg+" cat files/"+file));}
 private JSONObject project(String pkg,String file,String name)throws Exception{return named(archive(pkg,file).getJSONArray("projects"),name);}
 private JSONObject named(JSONArray values,String name)throws Exception{for(int i=0;i<values.length();i++){JSONObject value=values.getJSONObject(i);if(name.equals(value.getString("name")))return value;}throw new AssertionError("Saved synthetic record missing: "+name);}
 private JSONArray forOwner(JSONArray values,String field,String id)throws Exception{JSONArray result=new JSONArray();for(int i=0;i<values.length();i++){JSONObject value=values.getJSONObject(i);if(id.equals(value.getString(field)))result.put(value);}return result;}
 private void share(String pkg,String de,String en,String name,String...facts)throws Exception{
  File incoming=new File(evidence,"last-report.txt"),metadata=new File(evidence,"last-report.json"),failure=new File(evidence,"receiver-error.txt");for(File file:new File[]{incoming,metadata,failure})if(file.exists())assertTrue(file.delete());
  click(de,en);long until=SystemClock.uptimeMillis()+12000;while(SystemClock.uptimeMillis()<until&&pkg.equals(device.getCurrentPackageName()))SystemClock.sleep(100);assertNotEquals("Chooser must open",pkg,device.getCurrentPackageName());capture(name+"-chooser");String chooser=device.getCurrentPackageName();assertTrue("Only Android local share resolver",Arrays.asList("android","com.android.intentresolver").contains(chooser));expectedOwner=chooser;requireForeground("share-chooser");
  // Only this local controlled receiver is ever selected; no communication app or contact.
  click("SHK QA local receiver");String previousChooser=expectedOwner;expectedOwner=host.getPackageName();awaitOwnedReceiver(previousChooser);requireForeground("local-receiver");until=SystemClock.uptimeMillis()+12000;while(SystemClock.uptimeMillis()<until&&!metadata.isFile()&&!failure.isFile())SystemClock.sleep(100);
  assertFalse("Local receiver rejected actual share",failure.exists());assertTrue("Missing received report metadata",metadata.isFile());byte[] bytes=Files.readAllBytes(incoming.toPath());String text=new String(bytes,StandardCharsets.UTF_8);JSONObject receipt=new JSONObject(new String(Files.readAllBytes(metadata.toPath()),StandardCharsets.UTF_8));
  assertEquals(pkg+".reports",receipt.getString("authority"));assertEquals(bytes.length,receipt.getInt("byteCount"));assertTrue(receipt.getBoolean("temporaryReadGrant"));assertTrue(receipt.getBoolean("clipDataMatches"));String filename=receipt.getString("filename");assertTrue("Only own report filename read",filename.matches("[a-z0-9-]+\\.txt"));
  String sourceHash=device.executeShellCommand("run-as "+pkg+" sha256sum cache/shk-reports/"+filename).trim().split("\\s+")[0];assertEquals("Complete original file bytes must reach receiver",sourceHash,receipt.getString("sha256"));
  for(String fact:facts)assertTrue("Actual full report omitted "+fact,text.contains(fact));Files.write(new File(evidence,name+".txt").toPath(),bytes);save(name+"-receipt.json",receipt);capture(name+"-received");backTo(pkg);
 }
 private void awaitOwnedReceiver(String chooser){awaitOwnerTransition(chooser,host.getPackageName());}
 private void awaitOwnerTransition(String previous,String target){
  long deadline=SystemClock.uptimeMillis()+2000;
  do{if(NativeWindowPolicy.transitionReady(windows(),previous,target))return;
   if(SystemClock.uptimeMillis()>=deadline)break;SystemClock.sleep(50);
  }while(SystemClock.uptimeMillis()<=deadline);
  throw new AssertionError("Expected owner never became stable after actual transition");
 }
 private void save(String name,JSONObject value)throws Exception{Files.write(new File(evidence,name).toPath(),value.toString(2).getBytes(StandardCharsets.UTF_8));}
 private void capture(String name){try{evidence.mkdirs();device.dumpWindowHierarchy(new File(evidence,name+".xml"));assertTrue(device.takeScreenshot(new File(evidence,name+".png")));if(name.equals("kalte-unsaved-note-landscape")){
 android.os.ParcelFileDescriptor raw=InstrumentationRegistry.getInstrumentation().getUiAutomation().executeShellCommand("screencap -p");
 try(InputStream stream=new android.os.ParcelFileDescriptor.AutoCloseInputStream(raw)){Files.copy(stream,new File(evidence,name+"-raw.png").toPath(),java.nio.file.StandardCopyOption.REPLACE_EXISTING);}
 }}catch(Exception e){throw new AssertionError("Cannot capture actual UI evidence",e);}}
 private void event(String state){try{evidence.mkdirs();try(FileOutputStream out=new FileOutputStream(new File(evidence,"events.jsonl"),true)){out.write((new JSONObject().put("method",method).put("state",state).put("at",System.currentTimeMillis()).toString()+"\n").getBytes(StandardCharsets.UTF_8));}}catch(Exception e){throw new AssertionError(e);}}
}
