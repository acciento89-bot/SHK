"""Read-only pinned lineage/product guard; no build, network or native operation."""
import hashlib,json,pathlib,re
HERE=pathlib.Path(__file__).resolve().parent

def verify(repo,acceptance=HERE):
 acceptance=pathlib.Path(acceptance);repo=pathlib.Path(repo);line=json.loads((acceptance/'lineage.json').read_text());config=json.loads((acceptance/'flavors.json').read_text())
 def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
 original=acceptance/'fixtures/original-ShkWorkflowNativeTest.java.txt'
 if digest(original)!=line['source_sha256']:raise ValueError('Original native source lineage mismatch')
 expected=original.read_text().replace('onlyOwnedDisposableApi36()','onlyOwnedDisposableApi35()').replace('assertEquals(36,Build.VERSION.SDK_INT)','assertEquals(35,Build.VERSION.SDK_INT)')
 actual=(acceptance/'host/app/src/androidTest/java/de/kamilunavo/shknativeqa/ShkWorkflowNativeTest.java').read_text()
 if actual.count('@Test public void')!=5:raise ValueError('Exactly five original native methods required')
 if actual!=expected:
  host=acceptance/'host/app/src/androidTest/java/de/kamilunavo/shknativeqa/ShkWorkflowNativeTest.java'
  policy=host.with_name('NativeWindowPolicy.java')
  if digest(host)!=line.get('reviewed_host_sha256') or not policy.is_file() or digest(policy)!=line.get('reviewed_window_policy_sha256'):raise ValueError('Unreviewed native guard source')
  numeric=host.with_name('NumericInputTransaction.java')
  if not numeric.is_file() or digest(numeric)!=line.get('reviewed_numeric_transaction_sha256'):raise ValueError('Unreviewed numeric transaction source')
  identity=host.with_name('KalteNumericIdentity.java')
  if not identity.is_file() or digest(identity)!=line.get('reviewed_kalte_identity_sha256'):raise ValueError('Unreviewed numeric stage identity')
  ui=repo/'android/app/src/main/java/de/kamilunavo/shk/KalteServiceScreen.kt'
  if not ui.is_file() or digest(ui)!=line.get('reviewed_kalte_ui_sha256'):raise ValueError('Missing or unreviewed numeric UI test IDs')
  def business(s):return s[s.index(' @Test public void'):s.index(' private String unique(')]
  if business(actual)!=business(expected):raise ValueError('Original business scenario/assertion bytes changed')
 if digest(acceptance/'host/app/src/main/java/de/kamilunavo/shknativeqa/LocalReportReceiver.java')!=line['receiver_source_sha256']:raise ValueError('Actual local report receiver lineage mismatch')
 product=repo/'android/app/build.gradle.kts'
 if digest(product)!=line['product_gradle_sha256']:raise ValueError('Product Gradle changed: review flavor identity/version/SDK config before running acceptance')
 text=product.read_text();code=re.search(r'\bversionCode\s*=\s*(\d+)',text);name=re.search(r'\bversionName\s*=\s*"([^\"]+)"',text)
 if not code or not name:raise ValueError('Missing product identity')
 for flavor,c in config.items():
  block=re.search(r'create\("'+re.escape(flavor)+r'"\)\s*\{([^}]+)\}',text)
  if not block or 'applicationId = "'+c['package']+'"' not in block.group(1):raise ValueError('Flavor package identity mismatch')
  if c['versionCode']!=int(code.group(1)) or c['versionName']!=name.group(1):raise ValueError('Candidate version mismatch')
  if c['method'] not in line['methods']:raise ValueError('Unknown native method')
 if len(config)!=5:raise ValueError('Exactly five original native methods required')
 return True
if __name__=='__main__':verify(HERE.parents[1]);print('Pinned SHK product identities and original native assertions verified (source only)')
