#!/usr/bin/env python3
"""Exercise debug APK startup and durable capture recovery without model weights."""
from pathlib import Path
import json
import sqlite3
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'build/smoke'
OUTPUT.mkdir(parents=True, exist_ok=True)
PACKAGE = 'com.drena.simpen_woi'
ACTIVITY = f'{PACKAGE}/.MainActivity'
SIMULATOR = f'{PACKAGE}.simulator'
EXPECTED_NOTE = 'Pembayaran berhasil. Anda membayar Rp25000 di Warung Bu Tini.'


def adb(*args, check=True):
    return subprocess.run(['adb', *args], capture_output=True, check=check)


def launch(label, simulate=False):
    args = ['shell', 'am', 'start', '-W', '-n', ACTIVITY]
    if simulate:
        args.extend(['--ez', 'simpenwoi_simulate_capture', 'true'])
    result = adb(*args)
    (OUTPUT / f'{label}-launch.txt').write_bytes(result.stdout + result.stderr)
    assert b'Error:' not in result.stdout, 'Activity launch failed'


def copy_database(remote, local):
    result = adb('exec-out', 'run-as', PACKAGE, 'cat', remote, check=False)
    if result.returncode != 0 or not result.stdout.startswith(b'SQLite format 3\x00'):
        raise sqlite3.OperationalError('Database is not ready')
    local.write_bytes(result.stdout)
    # Drift can use WAL. Copy sidecars so reads see committed seed/transaction data.
    for suffix in ('-wal', '-shm'):
        sidecar = adb('exec-out', 'run-as', PACKAGE, 'cat', remote + suffix, check=False)
        target = Path(str(local) + suffix)
        if sidecar.returncode == 0:
            target.write_bytes(sidecar.stdout)
        elif target.exists():
            target.unlink()
    return sqlite3.connect(local)


def capture_snapshot(label):
    with copy_database('databases/capture_queue.db', OUTPUT / f'{label}-capture.sqlite') as database:
        database.row_factory = sqlite3.Row
        rows = database.execute('SELECT * FROM pending_captures').fetchall()
    assert len(rows) == 1, f'Expected one simulated capture, found {len(rows)}'
    row = dict(rows[0])
    assert row['source_package'] == SIMULATOR, 'Unexpected non-simulator capture'
    assert row['amount'] == 0 and row['direction'] == 'raw', 'Missing model must not guess a transaction'
    assert row['status'] == 'pending', 'Missing model must preserve the pending capture'
    assert row['note'] == EXPECTED_NOTE, 'Raw simulator text was not preserved'
    return row


def transaction_count(label):
    files = adb('shell', 'run-as', PACKAGE, 'find', '.', '-type', 'f').stdout.decode().splitlines()
    paths = [path.strip() for path in files if path.strip().endswith(('.sqlite', '.db'))
             and not path.strip().endswith('capture_queue.db')]
    for index, remote in enumerate(paths):
        try:
            with copy_database(remote, OUTPUT / f'{label}-app-{index}.sqlite') as database:
                table = database.execute("SELECT name FROM sqlite_master WHERE name = 'transactions'").fetchone()
                if table:
                    return database.execute('SELECT COUNT(*) FROM transactions').fetchone()[0]
        except sqlite3.OperationalError:
            continue
    raise sqlite3.OperationalError('Flutter transaction database is not ready')


def wait_for_pending(label):
    deadline = time.monotonic() + 30
    last_error = None
    while time.monotonic() < deadline:
        try:
            row = capture_snapshot(label)
            assert transaction_count(label) == 0, 'No model is installed; no financial transaction may be created'
            return row
        except (AssertionError, sqlite3.OperationalError) as error:
            last_error = error
            time.sleep(0.5)
    raise AssertionError(f'Capture recovery assertion timed out: {last_error}')


def diagnostics(label):
    logs = adb('logcat', '-d', '-v', 'threadtime').stdout
    (OUTPUT / f'{label}-logcat.txt').write_bytes(logs)
    (OUTPUT / f'{label}-screen.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
    activities = adb('shell', 'dumpsys', 'activity', 'activities').stdout
    (OUTPUT / f'{label}-activities.txt').write_bytes(activities)
    pid = adb('shell', 'pidof', PACKAGE, check=False)
    assert pid.returncode == 0 and pid.stdout.strip(), 'App exited; inspect startup logcat'
    assert any(PACKAGE.encode() in line and b'ResumedActivity' in line for line in activities.splitlines()), 'App is not foreground'
    assert not (b'FATAL EXCEPTION' in logs and PACKAGE.encode() in logs), 'Android process crash recorded'


def main():
    adb('install', '-r', str(ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'))
    # This is a fresh emulator test. Clear data before inspecting SQLite so all
    # persisted content belongs to this simulator, never a user's notifications.
    cleared = adb('shell', 'pm', 'clear', PACKAGE)
    assert b'Success' in cleared.stdout, 'Could not reset test data'
    adb('logcat', '-c')
    launch('initial')
    launch('simulate', simulate=True)  # Exercises onNewIntent on the shared Activity.
    before = wait_for_pending('before-restart')
    diagnostics('before-restart')
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch('reopened')
    after = wait_for_pending('after-restart')
    assert after == before, 'Cold restart changed or duplicated the pending capture'
    diagnostics('after-restart')
    (OUTPUT / 'capture-recovery.json').write_text(json.dumps({
        'capture_id': after['id'], 'pending_count': 1, 'transaction_count': 0,
        'raw_text_preserved': True, 'survived_force_stop': True,
        'real_model_inference_tested': False,
    }, indent=2) + '\n')
    print('PASS: APK startup, simulator raw queue, no-model no-write, and force-stop recovery')


if __name__ == '__main__':
    main()
