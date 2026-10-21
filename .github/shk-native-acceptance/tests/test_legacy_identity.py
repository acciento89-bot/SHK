import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[3]
QA=ROOT/'.github/shk-native-acceptance'
class LegacyIdentityTests(unittest.TestCase):
 def test_legacy_fields_expose_stable_identity_without_layout_change(self):
  s=(ROOT/'android/app/src/main/java/de/kamilunavo/shk/SHKApp.kt').read_text()
  self.assertIn('.testTag("shk-metric-" + title)',s)
  self.assertIn('testTagsAsResourceId = true',s)
 def test_kalte_legacy_writes_use_single_fresh_identity_transaction(self):
  s=(QA/'host/app/src/androidTest/java/de/kamilunavo/shknativeqa/ShkWorkflowNativeTest.java').read_text()
  self.assertIn('KalteNumericIdentity.legacyId(de)',s)
  self.assertIn('KalteNumericIdentity.legacyValue(field.getText())',s)
 def test_unused_screenshot_matrix_cannot_launch_automatically(self):
  s=(ROOT/'.github/workflows/android-store-screenshots.yml').read_text()
  trigger=s.split('on:',1)[1].split('permissions:',1)[0]
  self.assertNotIn('pull_request:',trigger)
  self.assertNotIn('push:',trigger)
