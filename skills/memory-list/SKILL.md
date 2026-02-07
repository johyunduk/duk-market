---
name: memory-list
description: SQLite DB에 저장된 모든 메모리를 카테고리별 통계와 함께 표시합니다
user-invocable: true
allowed-tools: Bash, Read
argument-hint: "[--category <type>] [--stats]"
---

# Memory List - 메모리 목록 및 통계

`~/.claude/duk-market.db`에서 저장된 메모리 목록을 조회합니다.

## DB 경로

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
```

## 인자 파싱

- `--category` 또는 `-c`: 특정 카테고리만
- `--stats`: 통계만 표시
- `--project` 또는 `-p`: 특정 프로젝트만
- `--limit` 또는 `-n`: 표시 개수 (기본: 20)

## 쿼리

### 카테고리별 목록 (기본)

```bash
sqlite3 -header -column "$DB" "
  SELECT id, category, title, author, project,
         strftime('%Y-%m-%d', created_at) as date
  FROM memories
  ORDER BY category, created_at DESC
  LIMIT $LIMIT;
"
```

### 카테고리별 통계 (`--stats`)

```bash
sqlite3 -header -column "$DB" "
  SELECT category, COUNT(*) as count
  FROM memories
  GROUP BY category
  ORDER BY count DESC;
"

sqlite3 -header -column "$DB" "
  SELECT project, COUNT(*) as count
  FROM memories
  GROUP BY project
  ORDER BY count DESC;
"

sqlite3 "$DB" "SELECT COUNT(*) FROM memories;"
sqlite3 "$DB" "SELECT COUNT(DISTINCT project) FROM memories;"
```

### 특정 카테고리

```bash
sqlite3 -header -column "$DB" "
  SELECT id, title, substr(content,1,80) as preview, author,
         strftime('%Y-%m-%d', created_at) as date
  FROM memories
  WHERE category = '$CATEGORY'
  ORDER BY created_at DESC
  LIMIT $LIMIT;
"
```

## 출력 형식

### 기본 목록

```
📚 저장된 메모리
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[decision] (2개)
  #12 2026-02-06 API 인증 JWT로 결정 (my-app)
  #8  2026-02-05 DB는 PostgreSQL 사용 (my-app)

[bugfix] (3개)
  #15 2026-02-06 useEffect 무한 루프 해결 (my-app)
  #11 2026-02-04 CORS 프록시 설정 (api-server)
  #9  2026-02-03 strict null 오류 (my-app)

[pattern] (1개)
  #10 2026-02-05 API 응답 형식 통일 (my-app)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 6개 메모리 | 2개 프로젝트
```

### 통계 (`--stats`)

```
📊 메모리 통계
━━━━━━━━━━━━━━━━━━━━━━━━

카테고리별:
  bugfix    ██████████  3개
  decision  ██████░░░░  2개
  pattern   ███░░░░░░░  1개

프로젝트별:
  my-app     ████████░░  5개
  api-server ██░░░░░░░░  1개

전체: 6개 | 최근 7일: 4개
```

## 사용 예시

```
/memory-list                # 전체 목록
/memory-list -c bugfix      # 버그 수정만
/memory-list --stats        # 통계
/memory-list -p my-app      # 특정 프로젝트
```
