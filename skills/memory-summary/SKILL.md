---
name: memory-summary
description: 현재 세션에서 수행한 작업을 자동 요약하여 SQLite DB의 sessions 테이블에 저장합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: ""
---

# Memory Summary - 세션 요약을 SQLite에 저장

현재 세션에서 변경된 내용을 분석하고 요약하여 DB에 저장합니다.

## DB 경로 및 초기화

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"

# sessions 테이블 확인
sqlite3 "$DB" "
  CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT UNIQUE,
    project TEXT,
    summary TEXT,
    files_changed TEXT DEFAULT '[]',
    decisions TEXT DEFAULT '[]',
    learnings TEXT DEFAULT '[]',
    todos TEXT DEFAULT '[]',
    started_at DATETIME DEFAULT (datetime('now','localtime')),
    ended_at DATETIME
  );
"
```

## 동작

### 1단계: 세션 작업 수집

```bash
# 변경된 파일
git diff --name-only
git diff --cached --name-only

# 오늘 커밋
git log --oneline --since="today" --author="$(git config user.name)"
```

### 2단계: 요약 생성

수집 정보를 분석하여:
- **summary**: 세션에서 한 작업 요약 (1-3문장)
- **files_changed**: 변경된 파일 목록 (JSON array)
- **decisions**: 결정사항 목록 (JSON array)
- **learnings**: 배운 점 목록 (JSON array)
- **todos**: 다음 할 일 (JSON array)

### 3단계: INSERT

```bash
PROJECT=$(basename "$(pwd)")

sqlite3 "$DB" "INSERT INTO sessions (project, summary, files_changed, decisions, learnings, todos)
  VALUES ('$PROJECT', '$SUMMARY', '$FILES_JSON', '$DECISIONS_JSON', '$LEARNINGS_JSON', '$TODOS_JSON');"
```

### 4단계: 중요 항목은 memories 테이블에도 저장

decisions와 learnings 중 중요한 것은 memories 테이블에도 자동 저장:
- decisions → `decision` 카테고리
- learnings → `til` 카테고리

## 출력 형식

```
📋 세션 요약 저장 완료
━━━━━━━━━━━━━━━━━━━━━━━━
요약:     Gemini CLI 연동 플러그인 추가
파일:     5개 생성, 2개 수정
배운 점:  2개 → memories에도 저장됨
TODO:     3개

💡 다음 세션에서 자동으로 이 요약이 컨텍스트에 주입됩니다
```

## 사용 예시

```
/memory-summary    # 현재 세션 요약 저장
```
