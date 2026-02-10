#!/usr/bin/env bash
# duk-memory: Load previous session context on SessionStart

set -e

DB="$HOME/.claude/duk-market.db"

# DB가 없으면 초기화
if [ ! -f "$DB" ]; then
  bash "$(dirname "$0")/init-db.sh" 2>/dev/null || exit 0
fi

PROJECT=$(basename "$(pwd)")

# --- 이전 세션 요약 ---
LAST_SESSION=$(sqlite3 -separator '|' "$DB" \
  "SELECT summary, files_changed, tools_used, started_at, ended_at
   FROM sessions
   WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
   ORDER BY ended_at DESC
   LIMIT 1;" 2>/dev/null || echo "")

if [ -n "$LAST_SESSION" ]; then
  echo "[duk-memory] 이전 세션 요약:"
  echo "$LAST_SESSION" | while IFS='|' read -r summary files tools started ended; do
    echo "  요약: $summary"
    echo "  변경 파일: $files"
    echo "  도구 사용: ${tools}회 | $started ~ $ended"
  done
  echo ""
fi

# --- 주요 결정사항 (최근 5개) ---
DECISIONS=$(sqlite3 "$DB" \
  "SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
   FROM memories
   WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
     AND category = 'decision'
   ORDER BY created_at DESC
   LIMIT 5;" 2>/dev/null || echo "")

if [ -n "$DECISIONS" ]; then
  echo "[duk-memory] 주요 결정사항:"
  echo "$DECISIONS" | while read -r line; do echo "  $line"; done
  echo ""
fi

# --- 주의사항 (최근 5개) ---
PITFALLS=$(sqlite3 "$DB" \
  "SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
   FROM memories
   WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
     AND category = 'pitfall'
   ORDER BY created_at DESC
   LIMIT 5;" 2>/dev/null || echo "")

if [ -n "$PITFALLS" ]; then
  echo "[duk-memory] 주의사항:"
  echo "$PITFALLS" | while read -r line; do echo "  $line"; done
  echo ""
fi

# --- 최근 버그 수정 (7일) ---
BUGFIXES=$(sqlite3 "$DB" \
  "SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
   FROM memories
   WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
     AND category = 'bugfix'
     AND created_at >= datetime('now', '-7 days', 'localtime')
   ORDER BY created_at DESC
   LIMIT 3;" 2>/dev/null || echo "")

if [ -n "$BUGFIXES" ]; then
  echo "[duk-memory] 최근 버그 수정 (7일):"
  echo "$BUGFIXES" | while read -r line; do echo "  $line"; done
  echo ""
fi

# --- 진행 중인 Duo Loop ---
ACTIVE_LOOP=$(sqlite3 "$DB" \
  "SELECT id, task, current_round, max_rounds
   FROM duo_loops
   WHERE status = 'in_progress'
   LIMIT 1;" 2>/dev/null || echo "")

if [ -n "$ACTIVE_LOOP" ]; then
  echo "[duk-memory] ⚠️ 중단된 Duo Loop: $ACTIVE_LOOP"
  echo "  /duo-status 로 확인하세요"
  echo ""
fi

exit 0
