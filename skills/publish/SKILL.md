---
name: market-publish
description: 현재 프로젝트의 Claude Code 확장 기능을 마켓플레이스에 공유할 수 있도록 패키징합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[--type skill|agent|hook|mcp|plugin]"
---

# Claude Code Extensions Marketplace - Publish

현재 프로젝트의 Claude Code 확장 기능을 다른 사용자가 설치할 수 있도록 패키징하고 공유합니다.

## 인자 파싱

- `--type` 또는 `-t`: 패키징할 확장 유형 (자동 감지 가능)
- `--name` 또는 `-n`: 확장 이름 (기본: 디렉토리 이름)

## 퍼블리시 프로세스

### 1단계: 현재 프로젝트 분석

현재 디렉토리에서 Claude Code 확장 요소를 자동 감지:

```
프로젝트 스캔 결과:
━━━━━━━━━━━━━━━━━━━━━━
발견된 확장 요소:
  ✓ skills/   - N개의 스킬
  ✓ agents/   - N개의 에이전트
  ✓ hooks/    - hooks.json
  ✓ .mcp.json - N개의 MCP 서버
  ✗ .claude-plugin/ - 플러그인 매니페스트 없음
```

### 2단계: plugin.json 생성/업데이트

`.claude-plugin/plugin.json`이 없으면 생성을 제안:

```json
{
  "name": "<project-name>",
  "version": "0.1.0",
  "description": "<사용자 입력>",
  "author": {
    "name": "<git config user.name>"
  },
  "repository": "<git remote url>",
  "license": "MIT",
  "keywords": [],
  "skills": "./skills/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json"
}
```

### 3단계: 유효성 검사

각 확장 요소의 유효성을 검사:

#### Skills 검증
- `SKILL.md` 파일 존재 확인
- YAML frontmatter 필수 필드: `name`, `description`
- `user-invocable: true`인 경우 `argument-hint` 권장

#### Agents 검증
- `.md` 파일에 YAML frontmatter 존재
- 필수 필드: `name`, `description`
- `tools` 또는 `allowed-tools` 지정 여부

#### Hooks 검증
- `hooks.json` 유효한 JSON
- 참조된 스크립트 파일 존재 확인
- 스크립트에 실행 권한 확인

#### MCP 검증
- `.mcp.json` 유효한 JSON
- `command` 경로 유효성

### 4단계: README 생성

`README.md`가 없거나 설치 방법이 없으면 추가 제안:

```markdown
## 설치

### Claude Code 플러그인으로 설치
\`\`\`bash
claude plugin add <owner>/<repo>
\`\`\`

### 마켓플레이스에서 설치
\`\`\`
/market-install <owner>/<repo>
\`\`\`

## 포함된 확장 기능

### Skills
- `/skill-name` - 설명

### Agents
- `agent-name` - 설명

### Hooks
- `event-name` - 설명
```

### 5단계: 공유 안내

```
📦 패키징 완료!

공유 방법:
1. GitHub에 푸시:
   git add . && git commit -m "feat: publish claude code extensions"
   git push origin main

2. 다른 사용자가 설치:
   /market-install <owner>/<repo>
   또는
   claude plugin add <owner>/<repo>

3. (선택) 큐레이션 목록에 등록:
   - awesome-claude-code에 PR 제출
   - GitHub 토픽에 "claude-code-plugin" 태그 추가
```

## 토픽 태그 권장

GitHub 레포에 다음 토픽 추가를 권장:
- `claude-code`
- `claude-code-plugin`
- `claude-code-skill` / `claude-code-agent` / `claude-code-hook` / `claude-code-mcp`
