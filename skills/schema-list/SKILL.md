---
name: schema-list
description: 프로젝트의 현재 스키마(DDL) 목록을 조회합니다. 테이블별 최신 버전만 표시합니다
user-invocable: true
allowed-tools: Bash, Read
argument-hint: "[--project <name>] [--all]"
---

# Schema List - 현재 스키마 현황 조회

`~/.claude/duk-market.db`의 `schemas` 테이블에서 프로젝트별 최신 스키마를 조회합니다.
테이블별로 **가장 최신 버전만** 표시합니다.

## DB 경로

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
```

## 인자 파싱

- 인자 없음: 현재 프로젝트 스키마만 표시
- `--project` 또는 `-p`: 특정 프로젝트 필터
- `--all`: 전체 프로젝트 스키마 표시

## 조회 쿼리

### 현재 프로젝트 스키마 (기본)

```bash
PROJECT=$(basename "$(pwd)")

sqlite3 -header -column "$DB" "
  SELECT s.table_name,
         'v' || s.version as version,
         s.change_type,
         s.note,
         s.created_at
  FROM schemas s
  INNER JOIN (
    SELECT table_name, MAX(version) as max_ver
    FROM schemas
    WHERE project = '$PROJECT'
    GROUP BY table_name
  ) latest ON s.table_name = latest.table_name
         AND s.version = latest.max_ver
         AND s.project = '$PROJECT'
  ORDER BY s.table_name;
"
```

### 특정 테이블의 현재 DDL 표시

최신 버전의 DDL 전문도 함께 표시합니다:

```bash
sqlite3 "$DB" "
  SELECT ddl FROM schemas
  WHERE project = '$PROJECT'
    AND table_name = '$TABLE_NAME'
  ORDER BY version DESC
  LIMIT 1;
"
```

### 전체 프로젝트 (--all)

```bash
sqlite3 -header -column "$DB" "
  SELECT s.project,
         s.table_name,
         'v' || s.version as version,
         s.change_type,
         s.created_at
  FROM schemas s
  INNER JOIN (
    SELECT project, table_name, MAX(version) as max_ver
    FROM schemas
    GROUP BY project, table_name
  ) latest ON s.project = latest.project
         AND s.table_name = latest.table_name
         AND s.version = latest.max_ver
  ORDER BY s.project, s.table_name;
"
```

## 출력 형식

```
현재 스키마 (my-app)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
테이블          버전   변경     메모                 날짜
users           v3     ALTER    avatar 컬럼 추가     2026-02-08
orders          v1     CREATE   주문 관리 테이블     2026-02-06
products        v2     ALTER    price 타입 변경      2026-02-07
sessions        v1     CREATE                        2026-02-05
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 4개 테이블

이력 보기: /schema-history <테이블명>
```

DB에 schemas 테이블이 없거나 비어있으면:

```
저장된 스키마가 없습니다.
/schema-save로 DDL을 저장하거나, Bash에서 DDL 실행 시 자동 감지됩니다.
```

## 사용 예시

```
/schema-list                    # 현재 프로젝트 스키마
/schema-list --all              # 전체 프로젝트
/schema-list -p my-api          # 특정 프로젝트
```
