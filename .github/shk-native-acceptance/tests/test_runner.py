import hashlib
import importlib.util,pathlib,tempfile,unittest,subprocess,json,tarfile,io,os
from unittest.mock import patch
ROOT=pathlib.Path(__file__).resolve().parents[1]
CONFIG=json.loads((ROOT/'flavors.json').read_text())
def load():
 spec=importlib.util.spec_from_file_location('runner',ROOT/'run_acceptance.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
class Fake:
 def __init__(self,flavor='kaltecalc',outcome='OK (1 test)',nonzero=False,timeout=False,version=None,versionname=None,sdk=35,missing=False,anr=False,keyboard="1",qemu="1"):
  self.config=CONFIG[flavor];self.outcome=outcome;self.nonzero=nonzero;self.timeout=timeout;self.version=self.config["versionCode"] if version is None else version;self.versionname=self.config["versionName"] if versionname is None else versionname;self.sdk=sdk;self.missing=missing;self.anr=anr;self.keyboard=keyboard;self.qemu=qemu;self.calls=[]
 def __call__(self,args,**kw):
  self.calls.append((args,kw['timeout']));s=' '.join(map(str,args));rc=0
  if 'ro.build.version.sdk' in s:out=str(self.sdk).encode()
  elif 'ro.kernel.qemu' in s:out=self.qemu.encode()
  elif 'settings get secure show_ime_with_hard_keyboard' in s:out=self.keyboard.encode()
  elif 'lastanr' in s:out=b'ANR com.android.systemui' if self.anr else b'No ANR since boot'
  elif 'dumpsys package' in s:out=f'versionCode={self.version} minSdk=26 targetSdk=36\nversionName={self.versionname}'.encode()
  elif 'instrument -w' in s:
   if self.timeout:raise subprocess.TimeoutExpired(args,kw['timeout'],output=b'PARTIAL_NATIVE',stderr=b'fixture timeout')
   out=self.outcome.encode();rc=1 if self.nonzero else 0
  elif 'cat files/'+self.config['archive'] in s:out=json.dumps({self.config['archive_list_key']:[]}).encode()
  elif 'tar -cf' in s:
   buf=io.BytesIO()
   with tarfile.open(fileobj=buf,mode='w') as t:
    if not self.missing:
     for name,data in {'events.jsonl':(json.dumps({'method':self.config['method'],'state':'PASS'})+'\n').encode(),'last-report.txt':b'QA synthetic','last-report.json':b'{}'}.items():
      info=tarfile.TarInfo('shk-native-qa/'+name);info.size=len(data);t.addfile(info,io.BytesIO(data))
   out=buf.getvalue()
  else:out=b'Success'
  return subprocess.CompletedProcess(args,rc,out,b'RETAIN_STDERR' if rc else b'')
class RunnerTests(unittest.TestCase):
 def fixture(self,fake,flavor='kaltecalc',serial='emulator-5554'):
  m=load()
  with tempfile.TemporaryDirectory() as d,patch.dict(os.environ,{'RUNNER_TEMP':d}):
   p=pathlib.Path(d);paths=[]
   for n in ['product.apk','host.apk','test.apk']:(p/n).write_bytes(n.encode());paths.append(p/n)
   proof=p/'shk-native-acceptance'/flavor
   r=m.run_acceptance('adb',serial,flavor,*paths,proof,execute=fake);self.files={f.name:f.read_bytes() for f in proof.iterdir()};return r
 def test_each_flavor_exact_method_only_own_three_apks(self):
  for flavor,c in CONFIG.items():
   fake=Fake(flavor);r=self.fixture(fake,flavor);self.assertEqual(r['status'],'PASSED');commands=[' '.join(x[0]) for x in fake.calls]
   instruments=[x for x in commands if 'instrument -w' in x];self.assertEqual(len(instruments),1);self.assertIn('#'+c['method'],instruments[0]);self.assertEqual(sum(' install -r ' in x for x in commands),3)
   self.assertEqual(set(r['apkSha256']),{'product','host','test'});self.assertFalse(any('pm clear' in x or 'purchase' in x.lower() or 'restore' in x.lower() for x in commands))
 def test_keyboard_precondition_is_set_and_read_back_before_install(self):
  f=Fake();r=self.fixture(f);self.assertEqual(r['status'],'PASSED');self.assertTrue(r['softwareKeyboardWithHardware'])
  commands=[' '.join(x[0]) for x in f.calls]
  put='adb -s emulator-5554 shell settings put secure show_ime_with_hard_keyboard 1';get='adb -s emulator-5554 shell settings get secure show_ime_with_hard_keyboard'
  self.assertEqual(commands.count(put),1);self.assertEqual(commands.count(get),1)
  self.assertLess(next(i for i,s in enumerate(commands) if 'lastanr' in s),commands.index(put));self.assertLess(commands.index(put),commands.index(get));self.assertLess(commands.index(get),next(i for i,s in enumerate(commands) if ' install -r ' in s))
 def test_keyboard_precondition_readback_fails_before_install(self):
  for value in ['0','null','unknown','1\n0']:
   f=Fake(keyboard=value);self.assertEqual(self.fixture(f)['status'],'FAILED');self.assertFalse(any('install' in x for x,t in f.calls))
 def test_keyboard_mutation_only_after_owned_emulator_preflight(self):
  for f,serial in [(Fake(sdk=36),'emulator-5554'),(Fake(qemu='0'),'emulator-5554'),(Fake(anr=True),'emulator-5554'),(Fake(),'personal-phone')]:
   self.assertEqual(self.fixture(f,serial=serial)['status'],'FAILED');self.assertFalse(any('settings' in x for x,t in f.calls))
 def test_nonzero_instrumentation_retains_stdout_and_stderr(self):
  r=self.fixture(Fake(outcome='REAL_ASSERTION_FAILURE',nonzero=True));self.assertEqual(r['status'],'FAILED');self.assertEqual(self.files['instrumentation.txt'],b'REAL_ASSERTION_FAILURE');self.assertEqual(self.files['instrumentation-stderr.txt'],b'RETAIN_STDERR')
 def test_timeout_retains_partial_and_bounds_and_stops_host(self):
  f=Fake(timeout=True);r=self.fixture(f);self.assertEqual(r['status'],'FAILED');self.assertEqual(self.files['instrumentation-partial.txt'],b'PARTIAL_NATIVE');self.assertTrue(all(t<=600 for _,t in f.calls));self.assertTrue(any('force-stop' in x and 'de.kamilunavo.shknativeqa' in x for x,t in f.calls))
 def test_native_failure_never_passes_or_dismisses_dialog(self):
  f=Fake(outcome='FAILURES!!! Tests run:1 Failures:1');r=self.fixture(f);self.assertEqual(r['status'],'FAILED');self.assertFalse(any('input' in x for x,t in f.calls))
 def test_wrong_candidate_does_not_run_instrumentation(self):
  f=Fake(version=CONFIG["kaltecalc"]["versionCode"]+1);self.assertEqual(self.fixture(f)['status'],'FAILED');self.assertFalse(any('instrument' in x for x,t in f.calls))
 def test_installed_version_suffix_is_not_exact_candidate(self):
  for version in [CONFIG['kaltecalc']['versionName']+'-beta',CONFIG['kaltecalc']['versionName']+'.1']:
   f=Fake(versionname=version);self.assertEqual(self.fixture(f)['status'],'FAILED');self.assertFalse(any('instrument' in x for x,t in f.calls))
 def test_wrong_sdk_and_system_anr_prevent_install(self):
  for f in [Fake(sdk=36),Fake(anr=True)]:
   self.assertEqual(self.fixture(f)['status'],'FAILED');self.assertFalse(any('install' in x for x,t in f.calls))
 def test_nonowned_serial_no_adb_calls(self):
  f=Fake();self.assertEqual(self.fixture(f,serial='personal-phone')['status'],'FAILED');self.assertEqual(f.calls,[])
 def test_missing_native_evidence_fails_even_instrumentation_ok(self):
  self.assertEqual(self.fixture(Fake(missing=True))['status'],'FAILED')
 def test_unknown_flavor_no_adb_calls(self):
  f=Fake();self.assertEqual(self.fixture(f,flavor='unknown')['status'],'FAILED');self.assertEqual(f.calls,[])
def require_manual_dispatch(source):
 allowed="workflow_dispatch:\n    inputs:\n      flavor:\n        description: 'One first validation or all five serial workflows'\n        type: choice\n        default: all\n        options: [all, kaltecalc, lueftungscalc, heizkoerpercalc, rohrcalc, anlagencheck]"
 block=source.split('on:\n',1)[1].split('permissions:',1)[0].strip()
 if block!=allowed:raise AssertionError('Only the exact reviewed workflow_dispatch inputs are allowed')
class SourceTests(unittest.TestCase):
 def test_lineage_preserves_business_scenarios_and_pins_reviewed_guards(self):
  line=json.loads((ROOT/'lineage.json').read_text());old=(ROOT/'fixtures/original-ShkWorkflowNativeTest.java.txt').read_text();now=(ROOT/'host/app/src/androidTest/java/de/kamilunavo/shknativeqa/ShkWorkflowNativeTest.java').read_text();self.assertEqual(old[old.index(' @Test public void'):old.index(' private String unique(')],now[now.index(' @Test public void'):now.index(' private String unique(')]);self.assertEqual(hashlib.sha256(now.encode()).hexdigest(),line['reviewed_host_sha256']);self.assertEqual(now.count('@Test public void'),5)
 def test_manual_serial_matrix_ciphertext_only(self):
  s=(ROOT.parents[0]/'workflows/shk-native-acceptance.yml').read_text();require_manual_dispatch(s);self.assertIn('fromJSON(inputs.flavor',s);self.assertIn('max-parallel: 1',s);self.assertIn('fail-fast: false',s);self.assertIn('target: google_apis',s);self.assertIn('-memory 2048',s);self.assertNotIn('secrets.',s)
  uploads=s.split('uses: actions/upload-artifact@v4');self.assertEqual(len(uploads),2);self.assertIn('path: ${{ runner.temp }}/shk-native-encrypted/${{ matrix.flavor }}/acceptance.cms',uploads[1]);self.assertNotIn('shk-native-acceptance/',uploads[1]);self.assertIn('if: always()',s)
 def test_manual_guard_rejects_every_extra_event(self):
  source=(ROOT.parents[0]/'workflows/shk-native-acceptance.yml').read_text();require_manual_dispatch(source)
  for event in ['push','pull_request','schedule','workflow_run','repository_dispatch','pull_request_target']:
   with self.subTest(event=event):
    with self.assertRaises(AssertionError):require_manual_dispatch(source.replace('on:\n','on:\n  '+event+':\n',1))
 def test_cleanup_fail_closed_inventory(self):
  spec=importlib.util.spec_from_file_location('cleanup',ROOT/'verify_cleanup.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
  self.assertTrue(m.verify_cleanup('', 'List of devices attached\n','owned','emulator-5554',0,0));self.assertFalse(m.verify_cleanup('', '', 'owned','emulator-5554',1,0));self.assertFalse(m.verify_cleanup('owned\n','', 'owned','emulator-5554',0,0))
if __name__=='__main__':unittest.main()
