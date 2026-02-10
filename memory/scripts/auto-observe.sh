#!/usr/bin/env bash
# duk-memory: Auto-capture observations from PostToolUse events (Docker)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/docker-up.sh" 2>/dev/null || exit 0

DB="/data/duk-market.db"

# Read hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || echo "")
PROJECT=$(basename "$(pwd)")

case "$TOOL_NAME" in
  Write|Edit)
    TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti = d.get('tool_input',{})
print(ti.get('file_path','') if isinstance(ti,dict) else '')
" 2>/dev/null || echo "")

    if [ -n "$TOOL_INPUT" ]; then
      SAFE_INPUT=$(echo "$TOOL_INPUT" | sed "s/'/''/g")
      docker exec duk-memory sqlite3 "$DB" \
        "INSERT INTO observations (tool_name, tool_input, project, session_id)
         VALUES ('$TOOL_NAME', '$SAFE_INPUT', '$PROJECT', '$SESSION_ID');"
    fi
    ;;
  Bash)
    TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ti = d.get('tool_input',{})
print(ti.get('command','')[:200] if isinstance(ti,dict) else '')
" 2>/dev/null || echo "")

    if [ -n "$TOOL_INPUT" ]; then
      SAFE_INPUT=$(echo "$TOOL_INPUT" | sed "s/'/''/g")
      docker exec duk-memory sqlite3 "$DB" \
        "INSERT INTO observations (tool_name, tool_input, project, session_id)
         VALUES ('Bash', '$SAFE_INPUT', '$PROJECT', '$SESSION_ID');"

      # DDL auto-detection
      DDL_MATCH=$(echo "$TOOL_INPUT" | grep -iE '(CREATE|ALTER|DROP)\s+(TABLE|INDEX|VIEW)' || echo "")
      if [ -n "$DDL_MATCH" ]; then
        docker exec -i duk-memory sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS schemas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  ddl TEXT NOT NULL,
  version INTEGER DEFAULT 1,
  change_type TEXT NOT NULL DEFAULT 'CREATE',
  project TEXT,
  session_id TEXT,
  note TEXT,
  created_at DATETIME DEFAULT (datetime('now','localtime'))
);
SQL

        echo "$TOOL_INPUT" | python3 -c "
import sys, re

text = sys.stdin.read()
pattern = r'(CREATE|ALTER|DROP)\s+(TABLE|INDEX|VIEW)\s+(?:IF\s+(?:NOT\s+)?EXISTS\s+)?['\"\`]?(\w+)['\"\`]?'
matches = re.findall(pattern, text, re.IGNORECASE)

for change_type_word, obj_type, name in matches:
    print(f'{change_type_word.upper()}|{name}')
" 2>/dev/null | while IFS='|' read -r CHANGE_TYPE TABLE_NAME; do
          if [ -n "$TABLE_NAME" ]; then
            SAFE_DDL=$(echo "$TOOL_INPUT" | sed "s/'/''/g")
            NEXT_VER=$(docker exec duk-memory sqlite3 "$DB" \
              "SELECT COALESCE(MAX(version), 0) + 1
               FROM schemas
               WHERE table_name = '$TABLE_NAME' AND project = '$PROJECT';")
            docker exec duk-memory sqlite3 "$DB" \
              "INSERT INTO schemas (table_name, ddl, version, change_type, project, session_id)
               VALUES ('$TABLE_NAME', '$SAFE_DDL', $NEXT_VER, '$CHANGE_TYPE', '$PROJECT', '$SESSION_ID');"
          fi
        done
      fi
    fi
    ;;
esac

exit 0
