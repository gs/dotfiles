#!/usr/bin/env python3
"""Model-free installed-resource smoke. Usage: python check-delivery-install.py [repo]."""
import json
import os
import selectors
import subprocess
import sys
import time

p = subprocess.Popen(
    ['pi', '--mode', 'rpc', '--no-session'],
    cwd=sys.argv[1] if len(sys.argv) > 1 else os.getcwd(),
    env={**os.environ, 'PI_OFFLINE': '1'},
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    bufsize=0,
)
selector = selectors.DefaultSelector()
selector.register(p.stdout, selectors.EVENT_READ)
selector.register(p.stderr, selectors.EVENT_READ)
commands = None
model = None
statuses = {}
errors = []
buffers = {p.stdout: b'', p.stderr: b''}
try:
    for request in [{'id': 'commands', 'type': 'get_commands'}, {'id': 'state', 'type': 'get_state'}]:
        p.stdin.write((json.dumps(request) + '\n').encode())
    p.stdin.flush()
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline and (commands is None or model is None):
        for key, _ in selector.select(1):
            chunk = os.read(key.fileobj.fileno(), 65536)
            if not chunk:
                selector.unregister(key.fileobj)
                continue
            buffers[key.fileobj] += chunk
            while b'\n' in buffers[key.fileobj]:
                line, buffers[key.fileobj] = buffers[key.fileobj].split(b'\n', 1)
                if key.fileobj is p.stderr:
                    errors.append(line.decode(errors='replace'))
                    continue
                try:
                    event = json.loads(line)
                except ValueError:
                    continue
                if event.get('type') == 'extension_ui_request' and event.get('method') == 'setStatus':
                    statuses[event.get('statusKey')] = event.get('statusText')
                if event.get('id') == 'commands':
                    commands = [c for c in event.get('data', {}).get('commands', []) if c.get('name') == 'delivery']
                if event.get('id') == 'state':
                    m = event.get('data', {}).get('model') or {}
                    model = '/'.join([m.get('provider', ''), m.get('id', '')])
    report = {'deliveryCommands': commands, 'model': model, 'deliveryStatus': statuses.get('delivery'), 'cavemanPresent': 'caveman' in statuses, 'stderr': errors}
    print(json.dumps(report, indent=2))
    if not commands or not statuses.get('delivery') or not model or model == '/' or errors:
        raise SystemExit(1)
finally:
    p.terminate()
    try:
        p.wait(timeout=5)
    except subprocess.TimeoutExpired:
        p.kill()
        p.wait()
    selector.close()
