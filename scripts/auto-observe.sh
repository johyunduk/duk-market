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
    fi
    ;;
esac

exit 0
