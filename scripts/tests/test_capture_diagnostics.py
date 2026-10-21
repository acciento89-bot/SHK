#!/usr/bin/env python3
"""Exercise the real capture helper with a temporary fake adb; never a device."""
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / '.github/scripts/capture-android-store-screenshots.sh'
PACKAGE = 'de.kamilunavo.heizkorpercalc'
MOCK_ADB = r'''#!/usr/bin/env python3
import json, os, pathlib, struct, sys
a = sys.argv[1:]
root = pathlib.Path(os.environ['MOCK_ROOT'])
with (root/'commands.jsonl').open('a') as f: f.write(json.dumps(a)+'\n')
case = os.environ['MOCK_CASE']
pkg = os.environ['PACKAGE_NAME']
dump = '<hierarchy><node package="android" text="System UI isn\'t responding"/><node text="Close app"/></hierarchy>'
if case == 'fullscreen': dump = '<hierarchy><node package="com.android.systemui" text="Viewing full screen"/><node text="Got it"/></hierarchy>'
if case == 'app-text': dump = '<hierarchy><node package="'+pkg+'" text="Got it"/><node text="HeizkörperCalc AUSLEGUNG"/></hierarchy>'
if case == 'clean': dump = '<hierarchy><node package="'+pkg+'" text="HeizkörperCalc AUSLEGUNG"/></hierarchy>'
if case == 'missing-text': dump = '<hierarchy><node package="'+pkg+'" text="SYNTHETIC_PRIVATE_UI_TIMEOUT_CONTENT"/></hierarchy>'
if a[:4] == ['shell','cmd','package','resolve-activity']:
    print('other.package/.Other' if case == 'bad-launcher' else pkg+'/de.kamilunavo.shk.MainActivity')
elif a[:3] == ['shell','dumpsys','window']:
    print('mCurrentFocus=Window{abc '+('com.android.systemui/.Dialog' if case=='fullscreen' else pkg+'/de.kamilunavo.shk.MainActivity')+'}')
elif a[:4] == ['shell','dumpsys','activity','lastanr']:
    print('Last ANR: synthetic system evidence')
elif a[:4] == ['shell','dumpsys','activity','exit-info']:
    print('ApplicationExitInfo synthetic reason=ANR')
elif a[:3] == ['shell','cat','/sdcard/window.xml'] or a[:3] == ['exec-out','uiautomator','dump']:
    print(dump)
elif a and a[0] == 'logcat':
    if case == 'diagnostic-timeout':
        import time
        time.sleep(5)
    if case == 'diagnostic-failure':
        print('synthetic logcat unavailable',file=sys.stderr); sys.exit(7)
    print('ActivityManager: synthetic ANR evidence')
elif a[:3] == ['exec-out','screencap','-p']:
    count_path=root/'screenshots'; n=int(count_path.read_text())+1 if count_path.exists() else 1
    count_path.write_text(str(n))
    sys.stdout.buffer.write(b'\x89PNG\r\n\x1a\n'+b'\0'*8+struct.pack('>II',1080,2400)+bytes([n]))
elif a[:3] == ['shell','am','start']:
    print('Status: ok')
else: print('Success')
'''


class CaptureDiagnostics(unittest.TestCase):
    def run_case(self, case):
        temporary = tempfile.TemporaryDirectory(prefix='shk-capture-fixture-')
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        bin_dir = root / 'bin'
        bin_dir.mkdir()
        adb = bin_dir / 'adb'
        adb.write_text(MOCK_ADB)
        adb.chmod(0o755)
        if case == 'missing-text':
            # Exercise the timeout branch promptly, without changing production retries.
            for name, body in [('seq','printf "1\\n"'),('sleep','exit 0')]:
                command = bin_dir/name
                command.write_text('#!/bin/sh\n'+body+'\n')
                command.chmod(0o755)
        (root / 'synthetic.apk').write_bytes(b'not-an-installed-apk')
        env = dict(os.environ, PATH=str(bin_dir)+os.pathsep+os.environ['PATH'],
                   MOCK_ROOT=str(root), MOCK_CASE=case, PACKAGE_NAME=PACKAGE,
                   GITHUB_WORKSPACE=str(root), APK_PATH='synthetic.apk',
                   OUTPUT_DIR='gallery', DIAGNOSTICS_DIR=str(root/'private-diagnostics'),
                   SECOND_ACTION='swipe', WAIT_TEXT='HeizkörperCalc', SECOND_WAIT_TEXT='AUSLEGUNG')
        result = subprocess.run(['bash', str(HELPER)], env=env, capture_output=True, timeout=15)
        commands = [json.loads(line) for line in (root/'commands.jsonl').read_text().splitlines()]
        return root, result, commands

    def assert_evidence(self, root, result):
        self.assertEqual(result.returncode, 1, result.stderr.decode())
        evidence = root / 'private-diagnostics'
        for name in ['window.txt', 'hierarchy.xml', 'last-anr.txt', 'exit-info.txt',
                     'logcat.txt', 'failure.png', 'metadata.json']:
            self.assertTrue((evidence/name).is_file(), name)
        metadata = json.loads((evidence/'metadata.json').read_text())
        self.assertEqual(metadata['captureExitCode'], 1)
        self.assertEqual(metadata['package'], PACKAGE)
        self.assertFalse(list((root/'gallery').glob('*.png')), 'Rejected frames must not become listing images')
        return evidence, metadata

    def test_anr_rejection_preserves_original_xml_focus_and_bounded_diagnostics(self):
        root, result, commands = self.run_case('anr')
        evidence, metadata = self.assert_evidence(root, result)
        self.assertIn("isn't responding", (evidence/'rejected-ui.xml').read_text())
        self.assertIn(PACKAGE, (evidence/'rejected-focus.txt').read_text())
        self.assertIn('synthetic system evidence', (evidence/'last-anr.txt').read_text())
        self.assertTrue((evidence/'failure.png').read_bytes().startswith(b'\x89PNG'))
        self.assertTrue(any(command[0]=='logcat' and '-t' in command for command in commands))
        self.assertEqual(metadata['diagnosticsAreListingScreenshots'], False)

    def test_fullscreen_prompt_still_fails_and_retains_its_actual_words(self):
        root, result, _ = self.run_case('fullscreen')
        evidence, _ = self.assert_evidence(root, result)
        self.assertIn('Viewing full screen', (evidence/'rejected-ui.xml').read_text())
        self.assertIn('com.android.systemui', (evidence/'rejected-focus.txt').read_text())

    def test_app_text_match_is_not_silently_accepted_or_called_an_anr(self):
        root, result, _ = self.run_case('app-text')
        evidence, metadata = self.assert_evidence(root, result)
        self.assertIn('package="'+PACKAGE+'"', (evidence/'rejected-ui.xml').read_text())
        self.assertNotEqual(metadata.get('diagnosis'), 'ANR')

    def test_one_failed_diagnostic_does_not_replace_original_failure_or_other_evidence(self):
        root, result, _ = self.run_case('diagnostic-failure')
        evidence, metadata = self.assert_evidence(root, result)
        self.assertEqual(metadata['commands']['logcat.txt']['exitCode'], 7)
        self.assertIn('unavailable', (evidence/'logcat.txt.stderr').read_text())

    def test_launcher_failure_also_preserves_failure_evidence(self):
        root, result, _ = self.run_case('bad-launcher')
        self.assert_evidence(root, result)

    def test_unresponsive_diagnostic_is_bounded_and_keeps_the_original_failure(self):
        root, result, _ = self.run_case('diagnostic-timeout')
        _, metadata = self.assert_evidence(root, result)
        self.assertTrue(metadata['commands']['logcat.txt']['timedOut'])
        self.assertIsNone(metadata['commands']['logcat.txt']['exitCode'])

    def test_timeout_keeps_private_hierarchy_out_of_public_action_logs(self):
        root, result, _ = self.run_case('missing-text')
        evidence, _ = self.assert_evidence(root, result)
        self.assertIn('SYNTHETIC_PRIVATE_UI_TIMEOUT_CONTENT',(evidence/'hierarchy.xml').read_text())
        self.assertNotIn(b'SYNTHETIC_PRIVATE_UI_TIMEOUT_CONTENT',result.stderr+result.stdout)

    def test_clean_capture_preserves_two_original_images_and_never_hides_dialogs(self):
        root, result, commands = self.run_case('clean')
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(len(list((root/'gallery').glob('*.png'))), 2)
        self.assertFalse((root/'private-diagnostics').exists())
        self.assertFalse(any('hide_error_dialogs' in command for command in commands))

    def test_workflow_always_preserves_diagnostics_separately_from_store_gallery(self):
        workflow = (ROOT/'.github/workflows/android-store-screenshots.yml').read_text()
        self.assertIn('name: Preserve capture failure diagnostics', workflow)
        section = workflow.split('name: Preserve capture failure diagnostics',1)[1].split('\n  persist:',1)[0]
        self.assertIn('if: always()', section)
        self.assertIn('name: SHK-${{ matrix.label }}-capture-diagnostics', section)
        self.assertIn('retention-days: 7', section)
        self.assertIn("pattern: SHK-*-authentic-Android-screenshots", workflow)
        self.assertIn('python3 scripts/tests/test_capture_diagnostics.py', workflow)


if __name__ == '__main__':
    unittest.main()
