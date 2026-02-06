---
name: market-info
description: Claude Code 확장 기능의 상세 정보를 표시합니다
user-invocable: true
allowed-tools: Bash, Read, WebFetch, Grep, Glob
argument-hint: "<repository-or-name>"
---

# Claude Code Extensions Marketplace - Info

GitHub 레포지토리 또는 로컬에 설치된 확장 기능의 상세 정보를 표시합니다.

## 인자 파싱

- `$0`: 레포지토리 (`owner/repo`) 또는 로컬 확장 이름

## 동작

### 원격 레포지토리인 경우 (`/` 포함)

```bash
# 레포 정보 가져오기
gh repo view "$REPO" --json name,description,url,stargazersCount,forksCount,updatedAt,licenseInfo,repositoryTopics

# README 확인
gh repo view "$REPO" --json readme
```

레포에서 확장 구성 요소를 파악:

```bash
# 파일 트리 확인
gh api "repos/$REPO/git/trees/HEAD?recursive=1" --jq '.tree[].path' | grep -E '(SKILL\.md|plugin\.json|\.mcp\.json|hooks\.json|agents/.*\.md)'
```

### 로컬 확장인 경우

로컬 설치 경로에서 파일을 읽어 정보를 표시.

## 출력 형식

```
📋 확장 정보: <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

설명:    <description>
저자:    <author>
버전:    <version>
라이선스: <license>
Stars:   ⭐ <count>
Forks:   🍴 <count>
업데이트: <last-updated>
레포:    <url>

포함된 확장 요소:
━━━━━━━━━━━━━━━━━
Skills (N개):
  - /skill-1: 설명...
  - /skill-2: 설명...

Agents (N개):
  - agent-1: 설명...

Hooks:
  - PreToolUse: Bash 커맨드 검증
  - PostToolUse: 자동 포맷팅

MCP Servers (N개):
  - server-1: 설명...

설치:
  /market-install <owner>/<repo>
```

## SKILL.md frontmatter 파싱

원격 레포의 SKILL.md를 가져와 frontmatter를 파싱:

```bash
gh api "repos/$REPO/contents/skills/name/SKILL.md" --jq '.content' | base64 -d | head -50
```

frontmatter에서 `name`, `description`, `allowed-tools`, `user-invocable` 등을 추출하여 표시.
