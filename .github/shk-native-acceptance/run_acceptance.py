"""One synthetic SHK flavor/method on the workflow-owned API35 emulator; no transactions."""
import argparse,datetime,hashlib,io,json,os,pathlib,re,subprocess,tarfile
ROOT=pathlib.Path(__file__).resolve().parent
CONFIG=json.loads((ROOT/'flavors.json').read_text())
HOST='de.kamilunavo.shknativeqa'
GENERIC_FILES={'result.json','source-commit.txt','product-build.log','host-build.log','installed-identity.txt','actual-archive.json','instrumentation.txt','instrumentation-stderr.txt','instrumentation-partial.txt','instrumentation-partial-stderr.txt','preflight-anr.txt','final-screen.png','window.txt','last-anr.txt','crash-log.txt','logcat.txt','final-ui.xml','emulator-stop.txt','avd-delete.txt','remaining-avds.txt','remaining-devices.txt','cleanup.json','cleanup-failed.txt'}
def run_acceptance(adb,serial,flavor,product,host,test,proof,execute=subprocess.run):
 proof=pathlib.Path(proof);runtime=pathlib.Path(os.environ['RUNNER_TEMP']).resolve()
 if proof.is_symlink() or proof.parent.is_symlink() or proof.resolve()!=(runtime/'shk-native-acceptance'/flavor).resolve():raise RuntimeError('Refusing evidence outside owned flavor scope')
 proof.mkdir(parents=True,exist_ok=True,mode=0o700)
 r={'status':'STARTED','flavor':flavor,'serial':serial,'transactions':False,'deviceCreated':False,'targetDataCleared':False,'deviceCleanupOwner':'run-cloud.sh EXIT plus emulator action post cleanup'}
 validated=False;started=False
 def call(args,timeout=15):
  result=execute([str(adb),'-s',serial,*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
  if result.returncode:
   if args[:3]==['shell','am','instrument']:
    (proof/'instrumentation.txt').write_bytes(result.stdout or b'');(proof/'instrumentation-stderr.txt').write_bytes(result.stderr or b'')
    raise RuntimeError('Native instrumentation command failed; retained privately')
   raise RuntimeError('adb operation failed: '+args[0])
  return result.stdout
 def capture(name,args):
  try:(proof/name).write_bytes(call(args,10))
  except BaseException as e:r.setdefault('diagnosticErrors',{})[name]=type(e).__name__
 try:
  if flavor not in CONFIG:raise RuntimeError('Unknown SHK flavor')
  c=CONFIG[flavor];r.update({'package':c['package'],'method':c['method'],'expectedVersion':f"{c['versionName']}({c['versionCode']})",'expectedApi':35})
  if serial!='emulator-5554':raise RuntimeError('Only the single workflow-owned emulator serial is permitted')
  if call(['shell','getprop','ro.build.version.sdk']).decode().strip()!='35':raise RuntimeError('Expected official API35 image')
  if call(['shell','getprop','ro.kernel.qemu']).decode().strip()!='1':raise RuntimeError('Physical device prohibited')
  validated=True
  anr=call(['shell','dumpsys','activity','lastanr']);(proof/'preflight-anr.txt').write_bytes(anr)
  if b'com.android.systemui' in anr.lower():raise RuntimeError('ENVIRONMENT_BLOCKED:SystemUI ANR; no dismissal')
  # The owned emulator reports a hardware keyboard; require normal phone IME behavior explicitly.
  call(['shell','settings','put','secure','show_ime_with_hard_keyboard','1'])
  if call(['shell','settings','get','secure','show_ime_with_hard_keyboard']).decode().strip()!='1':raise RuntimeError('Software keyboard precondition not established')
  r['softwareKeyboardWithHardware']=True
  r['apkSha256']={role:hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest() for role,p in [('product',product),('host',host),('test',test)]}
  for apk in [product,host,test]:call(['install','-r',str(apk)],90)
  identity=call(['shell','dumpsys','package',c['package']]);(proof/'installed-identity.txt').write_bytes(identity);info=identity.decode(errors='replace')
  if not re.search(r'\bversionCode='+str(c['versionCode'])+r'(?=\s|$)',info) or not re.search(r'\bversionName='+re.escape(c['versionName'])+r'(?=\s|$)',info):raise RuntimeError('Installed candidate identity mismatch')
  started=True
  result=call(['shell','am','instrument','-w','-r','-e','class',HOST+'.ShkWorkflowNativeTest#'+c['method'],HOST+'.test/androidx.test.runner.AndroidJUnitRunner'],600)
  (proof/'instrumentation.txt').write_bytes(result);text=result.decode(errors='replace')
  if 'OK (1 test)' not in text or any(x in text for x in ['FAILURES','INSTRUMENTATION_FAILED','Process crashed']):raise RuntimeError('Native assertions failed; retained privately')
  archive=call(['exec-out','run-as',c['package'],'cat','files/'+c['archive']]);data=json.loads(archive)
  if not isinstance(data.get(c['archive_list_key']),list):raise RuntimeError('Actual target archive shape mismatch')
  (proof/'actual-archive.json').write_bytes(archive);r['archiveSha256']=hashlib.sha256(archive).hexdigest();r['status']='PASSED'
 except BaseException as e:
  r['status']='FAILED';r['error']=str(e)
  if started and isinstance(e,subprocess.TimeoutExpired):
   if e.stdout:(proof/'instrumentation-partial.txt').write_bytes(e.stdout)
   if e.stderr:(proof/'instrumentation-partial-stderr.txt').write_bytes(e.stderr)
 finally:
  if validated:
   capture('final-screen.png',['exec-out','screencap','-p']);capture('window.txt',['shell','dumpsys','window','windows']);capture('last-anr.txt',['shell','dumpsys','activity','lastanr']);capture('crash-log.txt',['logcat','-d','-b','crash']);capture('logcat.txt',['logcat','-d','-t','2000'])
   try:
    call(['shell','uiautomator','dump','/sdcard/shk-native-final.xml'],10);capture('final-ui.xml',['exec-out','cat','/sdcard/shk-native-final.xml'])
   except BaseException as e:r.setdefault('diagnosticErrors',{})['final-ui.xml']=type(e).__name__
   try:
    packed=call(['exec-out','run-as',HOST,'tar','-cf','-','-C','files','shk-native-qa'],20)
    if len(packed)>64*1024*1024:raise RuntimeError('Native evidence tar exceeds cap')
    total=0
    with tarfile.open(fileobj=io.BytesIO(packed)) as t:
     for member in t.getmembers():
      if member.isdir():continue
      path=pathlib.PurePosixPath(member.name)
      if not member.isfile() or path.parent!=pathlib.PurePosixPath('shk-native-qa') or path.name not in CONFIG[flavor]['native_files'] or member.size>16*1024*1024:raise RuntimeError('Unexpected native evidence entry')
      total+=member.size
      if total>64*1024*1024:raise RuntimeError('Native evidence expanded size cap')
      target=proof/path.name
      if target.exists() or target.is_symlink():raise RuntimeError('Duplicate native evidence entry')
      with target.open('xb') as out:out.write(t.extractfile(member).read())
    events=[json.loads(line) for line in (proof/'events.jsonl').read_text().splitlines() if line]
    if not any(e.get('method')==CONFIG[flavor]['method'] and e.get('state')=='PASS' for e in events) or any(str(e.get('state','')).startswith('FAIL') for e in events):raise RuntimeError('Missing matching native PASS event')
    if r['status']=='PASSED' and not all((proof/f).is_file() for f in ['last-report.txt','last-report.json']):raise RuntimeError('Actual local report evidence missing')
   except BaseException as e:
    r.setdefault('diagnosticErrors',{})['nativeEvidence']=type(e).__name__
    if r['status']=='PASSED':r['status']='FAILED';r['error']='Native evidence extraction/verification incomplete'
   if started:
    try:call(['shell','am','force-stop',HOST],10)
    except BaseException as e:r.setdefault('diagnosticErrors',{})['hostStop']=type(e).__name__
  r['finishedUTC']=datetime.datetime.now(datetime.timezone.utc).isoformat();(proof/'result.json').write_text(json.dumps(r,indent=2)+'\n')
 return r

def main():
 os.umask(0o077);p=argparse.ArgumentParser();p.add_argument('--adb',default='adb');p.add_argument('--serial',default='emulator-5554');p.add_argument('--flavor',choices=CONFIG,required=True)
 for name in ['product','host','test','proof']:p.add_argument('--'+name,type=pathlib.Path,required=True)
 a=p.parse_args();r=run_acceptance(a.adb,a.serial,a.flavor,a.product,a.host,a.test,a.proof);print(json.dumps({'status':r['status'],'flavor':a.flavor,'evidence':'encrypted artifact only; no native output printed'}));raise SystemExit(0 if r['status']=='PASSED' else 1)
if __name__=='__main__':main()
