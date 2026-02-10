#!/usr/bin/env bash
# setup.sh - duk-gemini-duo 훅을 ~/.claude/settings.json에 등록

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

python3 - <<PYEOF
import json, os

settings_path = os.path.expanduser('~/.claude/settings.json')
script_dir = '${SCRIPT_DIR}'

try:
    with open(settings_path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

if 'hooks' not in data:
    data['hooks'] = {}

def register_hook(event, command, timeout):
    if event not in data['hooks']:
        data['hooks'][event] = []
    already = any(
        h.get('command') == command
        for entry in data['hooks'][event]
        for h in entry.get('hooks', [])
    )
    if not already:
        data['hooks'][event].append({'hooks': [{'type': 'command', 'command': command, 'timeout': timeout}]})
        return True
    return False

# duk-market gemini-duo 관련 이전 훅 정리
DUK_GEMINI_PREFIX = os.path.expanduser('~/.claude/plugins/cache/duk-market/duk-gemini-duo')
for event in list(data.get('hooks', {}).keys()):
    data['hooks'][event] = [
        entry for entry in data['hooks'][event]
        if not any(h.get('command', '').startswith(DUK_GEMINI_PREFIX) for h in entry.get('hooks', []))
    ]

changed = []
if register_hook('UserPromptSubmit', f'{script_dir}/auto-gemini.sh', 30):
    changed.append('UserPromptSubmit')

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)

if changed:
    print(f'[duk-gemini-duo] 훅 등록 완료: {", ".join(changed)}')
    print(f'[duk-gemini-duo] 경로: {script_dir}')
else:
    print(f'[duk-gemini-duo] 이미 등록됨')
PYEOF
