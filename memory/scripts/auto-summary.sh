#!/usr/bin/env bash
# duk-memory: Auto-save session summary on Stop event (Docker)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/docker-up.sh" 2>/dev/null || exit 0

DB="/data/duk-market.db"

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || echo "")
PROJECT=$(basename "$(pwd)")

# Ensure sessions table exists
docker exec -i duk-memory sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT,
  project TEXT,
  summary TEXT,
  files_changed TEXT DEFAULT '[]',
  tools_used INTEGER DEFAULT 0,
  started_at DATETIME,
  ended_at DATETIME DEFAULT (datetime('now','localtime'))
);
SQL

# Count observations for this session
OBS_COUNT=$(docker exec duk-memory sqlite3 "$DB" \
  "SELECT COUNT(*) FROM observations WHERE session_id = '$SESSION_ID';" 2>/dev/null || echo "0")

if [ "$OBS_COUNT" -lt 2 ]; then
  docker exec duk-memory sqlite3 "$DB" \
    "DELETE FROM observations WHERE created_at < datetime('now', '-30 days', 'localtime');" 2>/dev/null || true
  exit 0
fi

# Collect changed files
FILES=$(docker exec duk-memory sqlite3 "$DB" \
  "SELECT DISTINCT tool_input FROM observations
   WHERE session_id = '$SESSION_ID' AND tool_name IN ('Write', 'Edit')
   LIMIT 20;" 2>/dev/null || echo "")

FILES_JSON=$(echo "$FILES" | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(lines))
" 2>/dev/null || echo "[]")

SAFE_FILES=$(echo "$FILES_JSON" | sed "s/'/''/g")

STARTED=$(docker exec duk-memory sqlite3 "$DB" \
  "SELECT created_at FROM observations
   WHERE session_id = '$SESSION_ID'
   ORDER BY created_at ASC LIMIT 1;" 2>/dev/null || echo "")

docker exec duk-memory sqlite3 "$DB" \
  "INSERT INTO sessions (session_id, project, files_changed, tools_used, started_at)
   VALUES ('$SESSION_ID', '$PROJECT', '$SAFE_FILES', $OBS_COUNT, '$STARTED');"

# --- Cleanup ---
docker exec duk-memory sqlite3 "$DB" \
  "DELETE FROM observations WHERE session_id != '$SESSION_ID';" 2>/dev/null || true

docker exec duk-memory sqlite3 "$DB" \
  "DELETE FROM observations WHERE created_at < datetime('now', '-30 days', 'localtime');" 2>/dev/null || true

docker exec duk-memory sqlite3 "$DB" \
  "DELETE FROM sessions WHERE id NOT IN (
     SELECT id FROM sessions ORDER BY ended_at DESC LIMIT 50
   );" 2>/dev/null || true

docker exec duk-memory sqlite3 "$DB" \
  "DELETE FROM memories
   WHERE category = 'til'
     AND importance <= 3
     AND created_at < datetime('now', '-90 days', 'localtime');" 2>/dev/null || true

exit 0
