---
name: memory-recall
description: 저장된 메모리에서 키워드나 카테고리로 관련 지식을 검색하여 불러옵니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<검색어> [--category <type>] [--author <name>]"
---

# Memory Recall - 지식 검색

저장된 메모리 파일에서 키워드, 카테고리, 작성자 등으로 검색합니다.

## 인자 파싱

- `$0`, `$1`, ...: 검색 키워드
- `--category` 또는 `-c`: 카테고리 필터
- `--author` 또는 `-a`: 작성자 필터
- `--recent` 또는 `-r`: 최근 N일 이내 (기본: 전체)
- `--all`: 프로젝트 + 전역 메모리 모두 검색

## 검색 위치 (우선순위)

1. `.claude/memories/` (프로젝트 공유 메모리)
2. `.claude/memories/local/` (개인 메모리)
3. `~/.claude/memories/` (전역 메모리, `--all` 사용 시)

## 검색 방법

### 키워드 검색

메모리 파일들의 내용과 frontmatter에서 키워드를 검색:

```bash
# 프로젝트 메모리에서 검색
grep -rl "$KEYWORD" .claude/memories/ --include="*.md"

# frontmatter의 tags에서 검색
grep -rl "tags:.*$KEYWORD" .claude/memories/ --include="*.md"
```

### 카테고리 필터

```bash
# 특정 카테고리 디렉토리만 검색
ls .claude/memories/$CATEGORY/*.md
```

### 작성자 필터

```bash
grep -rl "author: $AUTHOR" .claude/memories/ --include="*.md"
```

### 최근 날짜 필터

```bash
find .claude/memories/ -name "*.md" -newer "$DATE_REF"
```

## 출력 형식

검색 결과를 다음 형식으로 표시:

```
🔍 메모리 검색: "$KEYWORD"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [bugfix] React useEffect 무한 루프 해결
   📅 2026-02-06 | 👤 johyunduk | 🏷️ react, hooks
   > useEffect 의존성 배열에 객체를 넣으면 매번 새 참조라 무한 루프 발생...
   📄 .claude/memories/bugfix/2026-02-06-react-useeffect-infinite-loop.md

2. [pattern] API 응답 형식 통일
   📅 2026-02-05 | 👤 kimdev | 🏷️ api, convention
   > 이 프로젝트에서는 API 응답을 항상 { data, error, meta } 형태로...
   📄 .claude/memories/pattern/2026-02-05-api-response-format.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 2개 발견 | 전체 내용: /memory-recall "$KEYWORD" --full
```

검색 결과 각 항목에서:
- frontmatter의 category, date, author, tags를 파싱하여 표시
- 내용의 첫 1-2줄을 미리보기로 표시
- `--full` 플래그 사용 시 전체 내용 표시

## 사용 예시

```
/memory-recall useEffect                    # 키워드 검색
/memory-recall react -c bugfix              # 카테고리 필터
/memory-recall -a johyunduk                 # 작성자 필터
/memory-recall docker -r 7                  # 최근 7일 이내
/memory-recall api pattern --all            # 전역 포함 검색
```
