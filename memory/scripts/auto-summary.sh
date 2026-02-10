#!/usr/bin/env bash
# duk-memory: Auto-save session summary on Stop event

set -e

DB="$HOME/.claude/duk-market.db"

[ -f "$DB" ] || exit 0

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || echo "")
PROJECT=$(basename "$(pwd)")

# 이 세션의 observation 수 확인
OBS_COUNT=$(sqlite3 "$DB" \
  "SELECT COUNT(*) FROM observations WHERE session_id = '$SESSION_ID';" 2>/dev/null || echo "0")

if [ "$OBS_COUNT" -lt 2 ]; then
  sqlite3 "$DB" \
    "DELETE FROM observations WHERE created_at < datetime('now', '-30 days', 'localtime');" 2>/dev/null || true
  exit 0
fi

# 변경된 파일 목록 수집
FILES=$(sqlite3 "$DB" \
  "SELECT DISTINCT tool_input FROM observations
   WHERE session_id = '$SESSION_ID' AND tool_name IN ('Write', 'Edit')
   LIMIT 20;" 2>/dev/null || echo "")

FILES_JSON=$(echo "$FILES" | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(lines))
" 2>/dev/null || echo "[]")

SAFE_FILES=$(echo "$FILES_JSON" | sed "s/'/''/g")

STARTED=$(sqlite3 "$DB" \
  "SELECT created_at FROM observations
   WHERE session_id = '$SESSION_ID'
   ORDER BY created_at ASC LIMIT 1;" 2>/dev/null || echo "")

sqlite3 "$DB" \
  "INSERT OR IGNORE INTO sessions (session_id, project, files_changed, tools_used, started_at)
   VALUES ('$SESSION_ID', '$PROJECT', '$SAFE_FILES', $OBS_COUNT, '$STARTED');"

# 오래된 데이터 정리
sqlite3 "$DB" \
  "DELETE FROM observations WHERE session_id != '$SESSION_ID';" 2>/dev/null || true

sqlite3 "$DB" \
  "DELETE FROM observations WHERE created_at < datetime('now', '-30 days', 'localtime');" 2>/dev/null || true

sqlite3 "$DB" \
  "DELETE FROM sessions WHERE id NOT IN (
     SELECT id FROM sessions ORDER BY ended_at DESC LIMIT 50
   );" 2>/dev/null || true

sqlite3 "$DB" \
  "DELETE FROM memories
   WHERE category = 'til'
     AND importance <= 3
     AND created_at < datetime('now', '-90 days', 'localtime');" 2>/dev/null || true

exit 0
