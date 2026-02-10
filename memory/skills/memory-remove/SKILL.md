---
name: memory-remove
description: SQLite DB에서 저장된 메모리를 삭제합니다
user-invocable: true
allowed-tools: Bash, Read
argument-hint: "<ID 또는 검색어> [--category <type>] [--before <date>]"
---

# Memory Remove - 메모리 삭제

`~/.claude/duk-market.db`에서 메모리를 삭제합니다.

## DB 경로

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"
```

## 인자 파싱

- `$0`: 삭제할 메모리 ID 또는 검색어
- `--category` 또는 `-c`: 카테고리 전체 삭제
- `--before <date>`: 특정 날짜 이전 삭제 (YYYY-MM-DD)
- `--force` 또는 `-f`: 확인 없이 삭제

## 삭제 쿼리

### ID로 삭제

```bash
# 먼저 확인
sqlite3 -header -column "$DB" "SELECT id, category, title, created_at FROM memories WHERE id = $ID;"
# 삭제
sqlite3 "$DB" "DELETE FROM memories WHERE id = $ID;"
```

### 카테고리 전체 삭제

```bash
sqlite3 "$DB" "SELECT COUNT(*) FROM memories WHERE category = '$CATEGORY';"
sqlite3 "$DB" "DELETE FROM memories WHERE category = '$CATEGORY';"
```

### 날짜 기준 삭제

```bash
sqlite3 "$DB" "DELETE FROM memories WHERE created_at < '$DATE';"
```

### 검색어로 찾아서 삭제

```bash
sqlite3 -header -column "$DB" "
  SELECT m.id, m.category, m.title
  FROM memories_fts fts JOIN memories m ON m.id = fts.rowid
  WHERE memories_fts MATCH '$KEYWORD';
"
```

사용자가 ID를 선택하면 해당 ID로 삭제.

## 출력 형식

```
🗑️ 삭제 완료: #42 [bugfix] React useEffect 무한 루프 해결
```

## 사용 예시

```
/memory-remove 42                        # ID로 삭제
/memory-remove -c til                    # TIL 전체 삭제
/memory-remove --before 2026-01-01       # 오래된 메모리 정리
/memory-remove useEffect                 # 검색 후 선택 삭제
```
