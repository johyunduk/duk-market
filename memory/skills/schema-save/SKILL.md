---
name: schema-save
description: DDL(CREATE TABLE 등)을 영구 저장합니다. 자동 감지 외에 수동으로 DDL을 저장할 때 사용합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<DDL문 또는 테이블명>"
---

# Schema Save - DDL 영구 저장

테이블 DDL을 `~/.claude/duk-market.db`의 `schemas` 테이블에 영구 저장합니다.
일반 memories와 달리 **만료 없이 영구 보관**되며, 같은 테이블명에 대해 **버전 이력**이 자동 관리됩니다.

## DB 경로 및 초기화

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"

# schemas 테이블 없으면 생성
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
  CREATE INDEX IF NOT EXISTS idx_schemas_table ON schemas(table_name);
  CREATE INDEX IF NOT EXISTS idx_schemas_project ON schemas(project);
"
```

## 인자 파싱

`$ARGUMENTS` 형식:
- DDL문 직접 입력: `CREATE TABLE users (id INT, name TEXT, ...)`
- 테이블명 + DDL: `users CREATE TABLE users (id INT PRIMARY KEY, ...)`
- 메모 포함: `CREATE TABLE users (...) --note 사용자 인증용 테이블`

DDL에서 자동 파싱할 정보:
- `table_name`: DDL에서 테이블명 추출
- `change_type`: CREATE / ALTER / DROP 자동 분류
- `note`: `--note` 뒤의 텍스트 (선택)

## 저장

```bash
PROJECT=$(basename "$(pwd)")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# table_name 파싱 (CREATE/ALTER/DROP TABLE 뒤의 이름)
# change_type 파싱 (CREATE/ALTER/DROP)

# 버전 자동 증가: 같은 table_name + project 기준
NEXT_VER=$(sqlite3 "$DB" "
  SELECT COALESCE(MAX(version), 0) + 1
  FROM schemas
  WHERE table_name = '$TABLE_NAME' AND project = '$PROJECT';
")

SAFE_DDL=$(echo "$DDL" | sed "s/'/''/g")
SAFE_NOTE=$(echo "$NOTE" | sed "s/'/''/g")

sqlite3 "$DB" "INSERT INTO schemas (table_name, ddl, version, change_type, project, session_id, note)
  VALUES ('$TABLE_NAME', '$SAFE_DDL', $NEXT_VER, '$CHANGE_TYPE', '$PROJECT', '$SESSION_ID', '$SAFE_NOTE');"

ID=$(sqlite3 "$DB" "SELECT last_insert_rowid();")
```

## 출력 형식

```
스키마 저장 완료 (ID: $ID)
━━━━━━━━━━━━━━━━━━━━━━━━
테이블:   users
버전:     v3 (ALTER)
프로젝트: my-app
메모:     avatar 컬럼 추가

조회: /schema-list
이력: /schema-history users
```

## 사용 예시

```
/schema-save CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT UNIQUE)
/schema-save ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'
/schema-save DROP TABLE temp_logs
/schema-save CREATE TABLE orders (id INT, user_id INT, total DECIMAL) --note 주문 관리 테이블
```
