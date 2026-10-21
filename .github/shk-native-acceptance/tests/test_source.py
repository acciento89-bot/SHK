import pathlib,tempfile,unittest,importlib.util,shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]
class SourceIdentityTests(unittest.TestCase):
 def module(self):
  spec=importlib.util.spec_from_file_location('verify',ROOT/'verify_source.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
 def test_exact_pinned_identity_and_host_pass(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);(p/'android/app').mkdir(parents=True);shutil.copyfile(ROOT/'fixtures/product-build.gradle.kts.txt',p/'android/app/build.gradle.kts');self.module().verify(p,ROOT)
 def test_unreviewed_candidate_version_fails_before_build(self):
  with tempfile.TemporaryDirectory() as d:
   p=pathlib.Path(d);(p/'android/app').mkdir(parents=True);(p/'android/app/build.gradle.kts').write_text((ROOT/'fixtures/product-build.gradle.kts.txt').read_text().replace('versionCode = 2','versionCode = 3'))
   with self.assertRaises(ValueError):self.module().verify(p,ROOT)
