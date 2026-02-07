---
name: memory-save
description: 세션에서 얻은 지식, 결정사항, 버그 수정, 패턴 등을 로컬 SQLite DB에 저장합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<카테고리> <내용>"
---

# Memory Save - 로컬 SQLite에 지식 저장

세션에서 얻은 지식을 `~/.claude/duk-market.db`에 저장합니다.

## DB 경로 및 초기화

```bash
DB="${DUK_MARKET_DB:-$HOME/.claude/duk-market.db}"

# DB가 없으면 초기화
if [ ! -f "$DB" ]; then
  mkdir -p "$(dirname "$DB")"
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
      title, content, tags, category,
      content='memories', content_rowid='id'
    );
    CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
      INSERT INTO memories_fts(rowid,title,content,tags,category)
      VALUES (new.id,new.title,new.content,new.tags,new.category);
    END;
  "
fi
```

## 인자 파싱

`$ARGUMENTS` 형식:
- `<category> <content>` - 카테고리와 내용 지정
- `<content>` - 카테고리 자동 분류

카테고리: `decision`, `bugfix`, `pattern`, `setup`, `pitfall`, `snippet`, `til`

자동 분류 힌트:
- "버그", "수정", "에러", "fix" → `bugfix`
- "결정", "선택", "쓰기로" → `decision`
- "패턴", "관례", "컨벤션" → `pattern`
- "설정", "설치", "환경" → `setup`
- "주의", "조심", "하면 안" → `pitfall`
- 기타 → `til`

## 저장

```bash
AUTHOR=$(git config user.name 2>/dev/null || echo "unknown")
PROJECT=$(basename "$(pwd)")

# 작은따옴표 이스케이프 필수
SAFE_TITLE=$(echo "$TITLE" | sed "s/'/''/g")
SAFE_CONTENT=$(echo "$CONTENT" | sed "s/'/''/g")

sqlite3 "$DB" "INSERT INTO memories (category, title, content, tags, author, project)
  VALUES ('$CATEGORY', '$SAFE_TITLE', '$SAFE_CONTENT', '$TAGS_JSON', '$AUTHOR', '$PROJECT');"

# 삽입된 ID 확인
ID=$(sqlite3 "$DB" "SELECT last_insert_rowid();")
```

## 출력 형식

```
💾 메모리 저장 완료 (ID: $ID)
━━━━━━━━━━━━━━━━━━━━━━━━
카테고리: bugfix
제목:     React useEffect 무한 루프 해결
태그:     react, hooks, useEffect
프로젝트: my-app

💡 검색: /memory-recall useEffect
   목록: /memory-list -c bugfix
```

## 사용 예시

```
/memory-save bugfix useEffect 의존성 배열에 객체를 넣으면 무한 루프 발생. useMemo로 해결
/memory-save pattern API 응답은 항상 { data, error, meta } 형태로 통일
/memory-save decision DB는 PostgreSQL 사용 - JSON 지원, 성숙한 생태계
/memory-save 오늘 배운 것: Next.js 서버 컴포넌트에서 useState 사용 불가
```
