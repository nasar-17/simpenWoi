#!/usr/bin/env python3
"""Install and launch the debug APK; this does not exercise model inference."""
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'build/smoke'
OUTPUT.mkdir(parents=True, exist_ok=True)
PACKAGE = 'com.drena.simpen_woi'

def adb(*args, check=True):
    return subprocess.run(['adb', *args], capture_output=True, check=check)

adb('install', '-r', str(ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'))
adb('logcat', '-c')
start = adb('shell', 'am', 'start', '-W', '-n', f'{PACKAGE}/.MainActivity')
(OUTPUT / 'launch.txt').write_bytes(start.stdout + start.stderr)
time.sleep(15)
logs = adb('logcat', '-d', '-v', 'threadtime').stdout
(OUTPUT / 'logcat.txt').write_bytes(logs)
(OUTPUT / 'screen.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
assert b'Error:' not in start.stdout, start.stdout.decode(errors='replace')
pid = adb('shell', 'pidof', PACKAGE, check=False)
assert pid.returncode == 0 and pid.stdout.strip(), 'App exited during startup; inspect logcat.txt'
activities = adb('shell', 'dumpsys', 'activity', 'activities').stdout
(OUTPUT / 'activities.txt').write_bytes(activities)
assert any(PACKAGE.encode() in line and b'ResumedActivity' in line for line in activities.splitlines()), 'App is not foreground'
assert not (b'FATAL EXCEPTION' in logs and PACKAGE.encode() in logs), 'Android process crash recorded'
print('PASS: APK installed and remained foreground after 15 seconds without a process crash')
