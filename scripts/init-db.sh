#!/usr/bin/env bash
# duk-market memory SQLite database initialization
# DB location: ~/.claude/duk-market.db

set -e

DB_PATH="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
mkdir -p "$(dirname "$DB_PATH")"

sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS memories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL DEFAULT 'til',
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT DEFAULT '[]',
  author TEXT,
  project TEXT,
  session_id TEXT,
  created_at DATETIME DEFAULT (datetime('now', 'localtime')),
  updated_at DATETIME DEFAULT (datetime('now', 'localtime'))
);

CREATE TABLE IF NOT EXISTS sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT UNIQUE,
  project TEXT,
  summary TEXT,
  files_changed TEXT DEFAULT '[]',
  decisions TEXT DEFAULT '[]',
  learnings TEXT DEFAULT '[]',
  todos TEXT DEFAULT '[]',
  started_at DATETIME DEFAULT (datetime('now', 'localtime')),
  ended_at DATETIME
);

CREATE TABLE IF NOT EXISTS duo_loops (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task TEXT NOT NULL,
  status TEXT DEFAULT 'in_progress',
  current_round INTEGER DEFAULT 0,
  max_rounds INTEGER DEFAULT 5,
  final_score INTEGER,
  rounds TEXT DEFAULT '[]',
  started_at DATETIME DEFAULT (datetime('now', 'localtime')),
  ended_at DATETIME
);

-- FTS5 full-text search index on memories
CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
  title, content, tags, category,
  content='memories',
  content_rowid='id'
);

-- Triggers to keep FTS index in sync
CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
  INSERT INTO memories_fts(rowid, title, content, tags, category)
  VALUES (new.id, new.title, new.content, new.tags, new.category);
END;

CREATE TRIGGER IF NOT EXISTS memories_ad AFTER DELETE ON memories BEGIN
  INSERT INTO memories_fts(memories_fts, rowid, title, content, tags, category)
  VALUES ('delete', old.id, old.title, old.content, old.tags, old.category);
END;

CREATE TRIGGER IF NOT EXISTS memories_au AFTER UPDATE ON memories BEGIN
  INSERT INTO memories_fts(memories_fts, rowid, title, content, tags, category)
  VALUES ('delete', old.id, old.title, old.content, old.tags, old.category);
  INSERT INTO memories_fts(rowid, title, content, tags, category)
  VALUES (new.id, new.title, new.content, new.tags, new.category);
END;

-- Observations: auto-captured tool use events
CREATE TABLE IF NOT EXISTS observations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tool_name TEXT,
  tool_input TEXT,
  tool_output TEXT,
  project TEXT,
  session_id TEXT,
  created_at DATETIME DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX IF NOT EXISTS idx_observations_session ON observations(session_id);
CREATE INDEX IF NOT EXISTS idx_observations_project ON observations(project);

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_memories_category ON memories(category);
CREATE INDEX IF NOT EXISTS idx_memories_project ON memories(project);
CREATE INDEX IF NOT EXISTS idx_memories_created ON memories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_project ON sessions(project);
SQL

echo "duk-market DB initialized: $DB_PATH"
