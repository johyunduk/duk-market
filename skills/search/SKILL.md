---
name: market-search
description: Claude Code 확장 마켓플레이스에서 키워드로 확장 기능을 검색합니다
user-invocable: true
allowed-tools: Bash, Read, WebFetch, WebSearch, Grep, Glob
argument-hint: "<keyword> [--category <type>]"
---

# Claude Code Extensions Marketplace - Search

사용자가 키워드로 Claude Code 확장 기능을 검색할 수 있도록 도와주세요.

## 인자 파싱

- `$ARGUMENTS`: 검색 키워드와 옵션
- `--category` 또는 `-c`: 카테고리 필터 (skills, agents, hooks, mcp-servers, plugins)
- `--sort`: 정렬 기준 (stars, updated, relevance) - 기본값: stars
- `--limit` 또는 `-n`: 결과 개수 - 기본값: 10

예시:
- `/market-search git hooks` → "git hooks" 키워드로 전체 검색
- `/market-search linter -c skills` → skills 카테고리에서 "linter" 검색
- `/market-search deploy --sort updated` → 최근 업데이트순으로 "deploy" 검색

## 검색 전략

### 1단계: GitHub 검색

```bash
# 기본 검색
gh search repos "claude-code $KEYWORD" --sort stars --limit $LIMIT --json name,description,url,stargazersCount,updatedAt

# 카테고리 필터가 있을 경우
gh search repos "claude-code $CATEGORY $KEYWORD" --sort stars --limit $LIMIT --json name,description,url,stargazersCount,updatedAt

# SKILL.md 파일이 있는 레포 검색
gh search code "SKILL.md $KEYWORD" --json repository,path
```

### 2단계: 웹 검색 보완

GitHub 검색 결과가 부족하면 웹 검색으로 보완합니다:
- `claude code $KEYWORD skill OR plugin OR hook OR agent site:github.com`

### 3단계: 큐레이션 목록 확인

awesome-claude-code 같은 큐레이션 목록에서 관련 항목을 확인합니다.

## 출력 형식

검색 결과를 다음 형식으로 표시:

```
검색: "$KEYWORD" (카테고리: $CATEGORY, 정렬: $SORT)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. repo-name ⭐ 123
   설명: ...
   카테고리: skill | agent | hook | mcp | plugin
   최근 업데이트: 2025-01-15
   설치: /market-install owner/repo

2. ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 N개 결과 | /market-search "$KEYWORD" --limit 20 으로 더 보기
```

## 검색 결과 검증

레포지토리가 실제 Claude Code 확장인지 확인:
1. `.claude-plugin/plugin.json` 존재 여부
2. `SKILL.md`, `.mcp.json`, `agents/*.md` 등 확장 파일 존재 여부
3. README에서 "claude code", "claude-code", "skill", "plugin" 등의 키워드 확인
