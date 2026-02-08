#!/usr/bin/env bash
# duk-market: Auto-capture observations from PostToolUse events
# Receives JSON via stdin from Claude Code hook system
# Automatically stores file edits, bash commands, and discoveries into SQLite

set -e

DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
mkdir -p "$(dirname "$DB")"

# Initialize DB if not exists
if [ ! -f "$DB" ]; then
  sqlite3 "$DB" "
    CREATE TABLE IF NOT EXISTS memories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL DEFAULT 'til',
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      tags TEXT DEFAULT '[]',
      author TEXT,
      project TEXT,
      created_at DATETIME DEFAULT (datetime('now','localtime')),
      updated_at DATETIME DEFAULT (datetime('now','localtime'))
    );
    CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
      title, content, tags, category, content='memories', content_rowid='id'
    );
    CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
      INSERT INTO memories_fts(rowid,title,content,tags,category)
      VALUES (new.id,new.title,new.content,new.tags,new.category);
    END;
    CREATE TABLE IF NOT EXISTS observations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tool_name TEXT,
      tool_input TEXT,
      tool_output TEXT,
      project TEXT,
      session_id TEXT,
      created_at DATETIME DEFAULT (datetime('now','localtime'))
    );
  "
fi

# Read hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null || echo "")
PROJECT=$(basename "$(pwd)")

# Only capture meaningful tool uses (Write, Edit, Bash with significant output)
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
      sqlite3 "$DB" "INSERT INTO observations (tool_name, tool_input, project, session_id)
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
      sqlite3 "$DB" "INSERT INTO observations (tool_name, tool_input, project, session_id)
        VALUES ('Bash', '$SAFE_INPUT', '$PROJECT', '$SESSION_ID');"

      # DDL auto-detection: capture CREATE/ALTER/DROP TABLE statements
      DDL_MATCH=$(echo "$TOOL_INPUT" | grep -iE '(CREATE|ALTER|DROP)\s+(TABLE|INDEX|VIEW)' || echo "")
      if [ -n "$DDL_MATCH" ]; then
        # Ensure schemas table exists
        sqlite3 "$DB" "
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
        " 2>/dev/null

        # Parse DDL details with python
        echo "$TOOL_INPUT" | python3 -c "
import sys, re

text = sys.stdin.read()
# Match CREATE/ALTER/DROP TABLE/INDEX/VIEW
pattern = r'(CREATE|ALTER|DROP)\s+(TABLE|INDEX|VIEW)\s+(?:IF\s+(?:NOT\s+)?EXISTS\s+)?['\"\`]?(\w+)['\"\`]?'
matches = re.findall(pattern, text, re.IGNORECASE)

for change_type_word, obj_type, name in matches:
    change_type = change_type_word.upper()
    table_name = name
    print(f'{change_type}|{table_name}')
" 2>/dev/null | while IFS='|' read -r CHANGE_TYPE TABLE_NAME; do
          if [ -n "$TABLE_NAME" ]; then
            SAFE_DDL=$(echo "$TOOL_INPUT" | sed "s/'/''/g")
            # Auto-increment version for same table_name + project
            NEXT_VER=$(sqlite3 "$DB" "
              SELECT COALESCE(MAX(version), 0) + 1
              FROM schemas
              WHERE table_name = '$TABLE_NAME' AND project = '$PROJECT';
            ")
            sqlite3 "$DB" "INSERT INTO schemas (table_name, ddl, version, change_type, project, session_id)
              VALUES ('$TABLE_NAME', '$SAFE_DDL', $NEXT_VER, '$CHANGE_TYPE', '$PROJECT', '$SESSION_ID');"
          fi
        done
      fi
    fi
    ;;
esac

exit 0
