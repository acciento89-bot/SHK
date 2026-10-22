import pathlib,tempfile,unittest,importlib.util,shutil,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
class SourceIdentityTests(unittest.TestCase):
 def module(self):
  spec=importlib.util.spec_from_file_location('verify',ROOT/'verify_source.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
 def fixture(self,p):
  ui=p/'android/app/src/main/java/de/kamilunavo/shk/KalteServiceScreen.kt';ui.parent.mkdir(parents=True,exist_ok=True)
  shutil.copyfile(ROOT/'fixtures/product-KalteServiceScreen.kt.txt',ui)
  shutil.copyfile(ROOT/'fixtures/product-SHKApp.kt.txt',ui.with_name('SHKApp.kt'))
  shutil.copyfile(ROOT/'fixtures/product-VentCommissioningScreen.kt.txt',ui.with_name('VentCommissioningScreen.kt'))
  shutil.copyfile(ROOT/'fixtures/product-RadiatorRetrofitScreen.kt.txt',ui.with_name('RadiatorRetrofitScreen.kt'))
  shutil.copyfile(ROOT/'fixtures/product-PipeCircuitScreen.kt.txt',ui.with_name('PipeCircuitScreen.kt'))
  shutil.copyfile(ROOT/'fixtures/product-ServiceHistoryScreen.kt.txt',ui.with_name('ServiceHistoryScreen.kt'))
  return ui
 def test_missing_reviewed_ui_fails_closed(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);self.fixture(p).unlink()
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)
 def test_tampered_reviewed_ui_fails_closed(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);ui=self.fixture(p);ui.write_text(ui.read_text()+'\n// unreviewed metadata change\n')
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)
 def test_exact_pinned_identity_and_host_pass(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);self.fixture(p);shutil.copyfile(ROOT/'fixtures/product-build.gradle.kts.txt',p/'android/app/build.gradle.kts');self.module().verify(p,ROOT)
 def test_unreviewed_candidate_version_fails_before_build(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);self.fixture(p);(p/'android/app/build.gradle.kts').write_text(re.sub(r'\bversionCode\s*=\s*(\d+)',lambda match:'versionCode = '+str(int(match.group(1))+1),(ROOT/'fixtures/product-build.gradle.kts.txt').read_text(),count=1))
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)

 def test_missing_service_ui_fails_closed(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);self.fixture(p).with_name('ServiceHistoryScreen.kt').unlink()
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)
 def test_tampered_service_ui_fails_closed(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);ui=self.fixture(p).with_name('ServiceHistoryScreen.kt');ui.write_text(ui.read_text()+'// unreviewed service form')
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)
