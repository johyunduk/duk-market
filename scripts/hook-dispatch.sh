#!/usr/bin/env bash
# duk-market: 버전 독립적 훅 디스패처
# installed_plugins.json에서 실제 installPath를 읽어 스크립트를 실행합니다.
# 사용법: hook-dispatch.sh <plugin-key> <relative-script-path>
#   예시: hook-dispatch.sh duk-memory memory/scripts/auto-observe.sh

PLUGIN_KEY="$1"
REL_SCRIPT="$2"

if [ -z "$PLUGIN_KEY" ] || [ -z "$REL_SCRIPT" ]; then
  exit 0
fi

INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"

if [ ! -f "$INSTALLED_JSON" ]; then
  exit 0
fi

INSTALL_PATH=$(python3 -c "
import json, sys
try:
    d = json.load(open('$INSTALLED_JSON'))
    entries = d.get('plugins', {}).get('$PLUGIN_KEY', [])
    if entries:
        print(entries[0].get('installPath', ''))
except:
    pass
" 2>/dev/null)

if [ -z "$INSTALL_PATH" ]; then
  exit 0
fi

SCRIPT="$INSTALL_PATH/$REL_SCRIPT"

if [ ! -f "$SCRIPT" ]; then
  exit 0
fi

# stdin을 그대로 전달하여 실행
/bin/bash "$SCRIPT"
