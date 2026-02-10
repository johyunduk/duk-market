#!/usr/bin/env bash
# setup.sh - duk-memory 훅을 ~/.claude/settings.json에 등록

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

python3 - <<PYEOF
import json, os, sys

settings_path = os.path.expanduser('~/.claude/settings.json')
script_dir = '${SCRIPT_DIR}'

try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

if 'hooks' not in data:
    data['hooks'] = {}

def register_hook(event, command, timeout, matcher='.*'):
    hook_entry = {'type': 'command', 'command': command, 'timeout': timeout}
    if event not in data['hooks']:
        data['hooks'][event] = []
    already = any(
        h.get('command') == command
        for entry in data['hooks'][event]
        for h in entry.get('hooks', [])
    )
    if not already:
        data['hooks'][event].append({'matcher': matcher, 'hooks': [hook_entry]})
        return True
    return False

def unregister_stale(event, prefix):
    """이전 버전 경로로 등록된 훅 제거"""
    if event not in data['hooks']:
        return
    data['hooks'][event] = [
        entry for entry in data['hooks'][event]
        if not any(
            h.get('command', '').startswith(prefix) and h.get('command') != entry
            for h in entry.get('hooks', [])
        )
    ]

# duk-market 관련 이전 훅 정리
DUK_PREFIX = os.path.expanduser('~/.claude/plugins/cache/duk-market/duk-memory')
for event in list(data.get('hooks', {}).keys()):
    data['hooks'][event] = [
        entry for entry in data['hooks'][event]
        if not any(h.get('command', '').startswith(DUK_PREFIX) for h in entry.get('hooks', []))
    ]

# 새 경로로 등록
changed = []
if register_hook('PostToolUse', f'{script_dir}/auto-observe.sh', 10):
    changed.append('PostToolUse')
if register_hook('SessionStart', f'{script_dir}/load-context.sh', 10):
    changed.append('SessionStart')

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)

if changed:
    print(f'[duk-memory] 훅 등록 완료: {", ".join(changed)}')
    print(f'[duk-memory] 경로: {script_dir}')
else:
    print(f'[duk-memory] 이미 등록됨')
PYEOF
