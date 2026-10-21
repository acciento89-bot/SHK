#!/usr/bin/env python3
"""Bounded, read-only evidence for a failed synthetic emulator capture."""
import json
import os
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone

os.umask(0o077)
destination = Path(sys.argv[1])
destination.mkdir(parents=True, exist_ok=True, mode=0o700)
package, status, stage = sys.argv[2], int(sys.argv[3]), sys.argv[4]
commands = {
    'window.txt': ['adb', 'shell', 'dumpsys', 'window'],
    'hierarchy.xml': ['adb', 'exec-out', 'uiautomator', 'dump', '/dev/tty'],
    'last-anr.txt': ['adb', 'shell', 'dumpsys', 'activity', 'lastanr'],
    'exit-info.txt': ['adb', 'shell', 'dumpsys', 'activity', 'exit-info', package],
    'logcat.txt': ['adb', 'logcat', '-d', '-t', '400', '-v', 'threadtime',
                   'ActivityManager:I', 'ActivityTaskManager:I', 'AndroidRuntime:V',
                   'WindowManager:I', 'SystemUI:W', '*:S'],
    'failure.png': ['adb', 'exec-out', 'screencap', '-p'],
}
metadata = {'recordedUTC': datetime.now(timezone.utc).isoformat(), 'package': package,
            'captureExitCode': status, 'stage': stage, 'commands': {},
            'diagnosticsAreListingScreenshots': False,
            'diagnosis': 'Unclassified; inspect the exact rejected tree and system evidence.'}
for name, command in commands.items():
    info = {'timeoutSeconds': 3}
    try:
        result = subprocess.run(command, capture_output=True, timeout=3)
        output, error = result.stdout, result.stderr
        info['exitCode'] = result.returncode
    except subprocess.TimeoutExpired as exc:
        output, error = exc.stdout or b'', exc.stderr or b''
        info.update(exitCode=None, timedOut=True)
    except OSError as exc:
        output, error = b'', str(exc).encode('utf-8')
        info.update(exitCode=None, errorType=type(exc).__name__)
    limit = 8 * 1024 * 1024 if name.endswith('.png') else 256 * 1024
    info['stdoutTruncated'] = len(output) > limit
    info['stderrTruncated'] = len(error) > 65536
    try:
        (destination/name).write_bytes(output[:limit])
        (destination/(name+'.stderr')).write_bytes(error[:65536])
    except OSError as exc:
        info['writeError'] = type(exc).__name__
    metadata['commands'][name] = info
(destination/'metadata.json').write_text(json.dumps(metadata, indent=2)+'\n')
