#!/usr/bin/env python3
"""Run the real app workflow on one available iPhone and iPad, preserving screenshots."""
import json, os, pathlib, subprocess, sys
scheme = sys.argv[1]
raw = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))
devices = [d for runtime, rows in raw['devices'].items() if 'iOS' in runtime for d in rows if d.get('isAvailable')]
out = pathlib.Path('review-results'); out.mkdir(exist_ok=True)
for family in ['iPhone', 'iPad']:
    device = next((d for d in devices if d['name'].startswith(family)), None)
    if not device:
        raise SystemExit(f'No available {family} simulator; cannot complete device validation')
    if device.get('state') != 'Booted':
        subprocess.run(['xcrun', 'simctl', 'boot', device['udid']], check=True)
    subprocess.run(['xcrun', 'simctl', 'bootstatus', device['udid'], '-b'], check=True)
    result = out / f'{scheme}-{family}.xcresult'
    command = ['xcodebuild', 'test', '-project', 'KamilunavoSHK.xcodeproj', '-scheme', scheme,
               '-destination', 'platform=iOS Simulator,id=' + device['udid'], '-parallel-testing-enabled', 'NO',
               '-resultBundlePath', str(result), 'CODE_SIGNING_ALLOWED=NO']
    completed = subprocess.run(command)
    if result.exists():
        subprocess.run(['xcrun', 'xcresulttool', 'export', 'attachments', '--path', str(result),
                        '--output-path', str(out / f'{scheme}-{family}-screenshots')], check=True)
    if completed.returncode:
        raise SystemExit(completed.returncode)
    subprocess.run(['xcrun', 'simctl', 'shutdown', device['udid']], check=False)
