#!/usr/bin/env bash
# duk-market: Load previous session context on SessionStart
# Outputs context to stdout (injected into Claude's context automatically)
# Total output kept under ~500 tokens

set -e

DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"

if [ ! -f "$DB" ]; then
  exit 0
fi

PROJECT=$(basename "$(pwd)")

# --- Previous session summary (LIMIT 1) ---
LAST_SESSION=$(sqlite3 -separator '|' "$DB" "
  SELECT summary, files_changed, tools_used, started_at, ended_at
  FROM sessions
  WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
  ORDER BY ended_at DESC
  LIMIT 1;
" 2>/dev/null || echo "")

if [ -n "$LAST_SESSION" ]; then
  echo "[duk-market] 이전 세션 요약:"
  echo "$LAST_SESSION" | while IFS='|' read -r summary files tools started ended; do
    echo "  요약: $summary"
    echo "  변경 파일: $files"
    echo "  도구 사용: ${tools}회 | $started ~ $ended"
  done
  echo ""
fi

# --- Key memories: decision (LIMIT 5) ---
DECISIONS=$(sqlite3 "$DB" "
  SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
  FROM memories
  WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
    AND category = 'decision'
  ORDER BY created_at DESC
  LIMIT 5;
" 2>/dev/null || echo "")

if [ -n "$DECISIONS" ]; then
  echo "[duk-market] 주요 결정사항:"
  echo "$DECISIONS" | while read -r line; do
    echo "  $line"
  done
  echo ""
fi

# --- Key memories: pitfall (LIMIT 5) ---
PITFALLS=$(sqlite3 "$DB" "
  SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
  FROM memories
  WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
    AND category = 'pitfall'
  ORDER BY created_at DESC
  LIMIT 5;
" 2>/dev/null || echo "")

if [ -n "$PITFALLS" ]; then
  echo "[duk-market] 주의사항:"
  echo "$PITFALLS" | while read -r line; do
    echo "  $line"
  done
  echo ""
fi

# --- Key memories: recent bugfix (LIMIT 3) ---
BUGFIXES=$(sqlite3 "$DB" "
  SELECT '#' || id || ' ' || title || ': ' || substr(content,1,80)
  FROM memories
  WHERE project = '$(echo "$PROJECT" | sed "s/'/''/g")'
    AND category = 'bugfix'
    AND created_at >= datetime('now', '-7 days', 'localtime')
  ORDER BY created_at DESC
  LIMIT 3;
" 2>/dev/null || echo "")

if [ -n "$BUGFIXES" ]; then
  echo "[duk-market] 최근 버그 수정 (7일):"
  echo "$BUGFIXES" | while read -r line; do
    echo "  $line"
  done
  echo ""
fi

# --- Active Duo Loop check ---
ACTIVE_LOOP=$(sqlite3 "$DB" "
  SELECT id, task, current_round, max_rounds
  FROM duo_loops
  WHERE status = 'in_progress'
  LIMIT 1;
" 2>/dev/null || echo "")

if [ -n "$ACTIVE_LOOP" ]; then
  echo "[duk-market] ⚠️ 중단된 Duo Loop: $ACTIVE_LOOP"
  echo "  /duo-status 로 확인하세요"
  echo ""
fi

exit 0
