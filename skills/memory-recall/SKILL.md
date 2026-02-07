---
name: memory-recall
description: SQLite DB에서 키워드나 카테고리로 저장된 지식을 검색합니다 (FTS5 전문 검색)
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<검색어> [--category <type>] [--limit <N>]"
---

# Memory Recall - SQLite FTS5 검색

`~/.claude/duk-market.db`에서 저장된 메모리를 전문 검색합니다.

## DB 경로

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
```

## 인자 파싱

- `$0`, `$1`, ...: 검색 키워드
- `--category` 또는 `-c`: 카테고리 필터
- `--project` 또는 `-p`: 프로젝트 필터
- `--limit` 또는 `-n`: 결과 수 (기본: 10)
- `--recent` 또는 `-r`: 최근 N일 이내
- `--id`: 특정 ID의 메모리 전체 내용 표시

## 검색 쿼리

### FTS5 키워드 검색 (기본)

```bash
sqlite3 -header -column "$DB" "
  SELECT m.id, m.category, m.title,
         substr(m.content, 1, 100) as preview,
         m.tags, m.author, m.project, m.created_at
  FROM memories_fts fts
  JOIN memories m ON m.id = fts.rowid
  WHERE memories_fts MATCH '$KEYWORD'
  ORDER BY rank
  LIMIT $LIMIT;
"
```

### 카테고리 필터

```bash
sqlite3 -header -column "$DB" "
  SELECT id, category, title, substr(content,1,100) as preview,
         tags, author, project, created_at
  FROM memories
  WHERE category = '$CATEGORY'
  ORDER BY created_at DESC
  LIMIT $LIMIT;
"
```

### 카테고리 + 키워드

```bash
sqlite3 -header -column "$DB" "
  SELECT m.id, m.category, m.title, substr(m.content,1,100) as preview,
         m.tags, m.author, m.project, m.created_at
  FROM memories_fts fts
  JOIN memories m ON m.id = fts.rowid
  WHERE memories_fts MATCH '$KEYWORD'
    AND m.category = '$CATEGORY'
  ORDER BY rank
  LIMIT $LIMIT;
"
```

### 최근 N일

```bash
sqlite3 -header -column "$DB" "
  SELECT id, category, title, substr(content,1,100) as preview,
         tags, author, created_at
  FROM memories
  WHERE created_at >= datetime('now', '-$DAYS days', 'localtime')
  ORDER BY created_at DESC
  LIMIT $LIMIT;
"
```

### 특정 ID 전체 조회

```bash
sqlite3 -header -column "$DB" "
  SELECT * FROM memories WHERE id = $ID;
"
```

## 출력 형식

```
🔍 메모리 검색: "$KEYWORD"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#42 [bugfix] React useEffect 무한 루프 해결
    📅 2026-02-06 | 👤 johyunduk | 🏷️ react, hooks
    > useEffect 의존성 배열에 객체를 넣으면 매번 새 참조라...
    💡 전체 보기: /memory-recall --id 42

#38 [pattern] API 응답 형식 통일
    📅 2026-02-05 | 👤 johyunduk | 🏷️ api, convention
    > 이 프로젝트에서는 API 응답을 항상 { data, error, meta }...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 2개 발견
```

## 사용 예시

```
/memory-recall useEffect                    # FTS5 키워드 검색
/memory-recall react -c bugfix              # 카테고리 필터
/memory-recall docker -r 7                  # 최근 7일 이내
/memory-recall --id 42                      # ID로 전체 내용 보기
/memory-recall api -p my-app                # 프로젝트 필터
```
