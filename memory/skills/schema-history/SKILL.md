---
name: schema-history
description: 특정 테이블의 DDL 변경 이력을 버전별로 조회합니다
user-invocable: true
allowed-tools: Bash, Read
argument-hint: "<테이블명> [--project <name>]"
---

# Schema History - 테이블 DDL 변경 이력

특정 테이블의 DDL 변경 이력을 버전 순서대로 표시합니다.
CREATE → ALTER → ALTER 순으로 스키마가 어떻게 진화했는지 추적할 수 있습니다.

## DB 경로

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
```

## 인자 파싱

- `$ARGUMENTS`의 첫 번째 단어: 테이블명 (필수)
- `--project` 또는 `-p`: 프로젝트 필터 (기본: 현재 디렉토리)

테이블명이 없으면 오류:
```
사용법: /schema-history <테이블명>
예시: /schema-history users
```

## 조회 쿼리

### 전체 이력

```bash
PROJECT=$(basename "$(pwd)")
TABLE_NAME="$1"

sqlite3 -header -column "$DB" "
  SELECT id,
         'v' || version as version,
         change_type,
         note,
         created_at
  FROM schemas
  WHERE table_name = '$TABLE_NAME'
    AND project = '$PROJECT'
  ORDER BY version ASC;
"
```

### 각 버전의 DDL 전문

```bash
sqlite3 "$DB" "
  SELECT version, change_type, ddl, note, created_at
  FROM schemas
  WHERE table_name = '$TABLE_NAME'
    AND project = '$PROJECT'
  ORDER BY version ASC;
"
```

## 출력 형식

```
스키마 이력: users (my-app)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

v1 (CREATE - 2026-02-05)
  CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE
  );

v2 (ALTER - 2026-02-07)
  메모: role 컬럼 추가
  ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user';

v3 (ALTER - 2026-02-08)
  메모: avatar 컬럼 추가
  ALTER TABLE users ADD COLUMN avatar_url TEXT;

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 3개 버전 | 최신: v3 (ALTER)
```

테이블이 없으면:
```
'users' 테이블의 스키마 이력이 없습니다.
/schema-save로 DDL을 저장하세요.
```

## 사용 예시

```
/schema-history users               # users 테이블 이력
/schema-history orders -p my-api    # 특정 프로젝트
```
