import pathlib,unittest
ROOT=pathlib.Path(__file__).resolve().parents[3]
class VentIdentityTests(unittest.TestCase):
 def test_each_mutually_exclusive_form_exposes_exact_field_identity(self):
  s=(ROOT/'android/app/src/main/java/de/kamilunavo/shk/VentCommissioningScreen.kt').read_text()
  for name in ['name','target','measured','note']:self.assertIn('.testTag("vent-field-'+name+'")',s)
  self.assertIn('testTagsAsResourceId = true',s)
