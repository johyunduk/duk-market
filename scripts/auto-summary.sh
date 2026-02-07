#!/usr/bin/env bash
# duk-market: Auto-save session summary on Stop event
# Collects observations from current session and stores a summary

set -e

DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"

if [ ! -f "$DB" ]; then
  exit 0
fi

# Read hook input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || echo "")
PROJECT=$(basename "$(pwd)")

# Ensure sessions table exists
sqlite3 "$DB" "
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
"

# Count observations for this session
OBS_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM observations WHERE session_id = '$SESSION_ID';" 2>/dev/null || echo "0")

# Skip if no meaningful work was done
if [ "$OBS_COUNT" -lt 2 ]; then
  exit 0
fi

# Collect changed files from observations
FILES=$(sqlite3 "$DB" "
  SELECT DISTINCT tool_input FROM observations
  WHERE session_id = '$SESSION_ID' AND tool_name IN ('Write', 'Edit')
  LIMIT 20;
" 2>/dev/null || echo "")

FILES_JSON=$(echo "$FILES" | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(lines))
" 2>/dev/null || echo "[]")

SAFE_FILES=$(echo "$FILES_JSON" | sed "s/'/''/g")

# Get first observation time as session start
STARTED=$(sqlite3 "$DB" "
  SELECT created_at FROM observations
  WHERE session_id = '$SESSION_ID'
  ORDER BY created_at ASC LIMIT 1;
" 2>/dev/null || echo "")

# Insert session record
sqlite3 "$DB" "INSERT INTO sessions (session_id, project, files_changed, tools_used, started_at)
  VALUES ('$SESSION_ID', '$PROJECT', '$SAFE_FILES', $OBS_COUNT, '$STARTED');"

exit 0
