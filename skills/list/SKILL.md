---
name: market-list
description: 현재 설치된 모든 Claude Code 확장 기능을 목록으로 표시합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[--scope user|project|local|all]"
---

# Claude Code Extensions Marketplace - List

현재 환경에 설치된 모든 Claude Code 확장 기능을 탐색하고 목록으로 표시합니다.

## 인자 파싱

- `--scope` 또는 `-s`: 범위 필터 (user, project, local, all) - 기본값: all
- `--type` 또는 `-t`: 유형 필터 (skills, agents, hooks, mcp, plugins)

## 검색 위치

### User 범위 (~)
```
~/.claude/skills/*/SKILL.md
~/.claude/agents/*.md
~/.claude/settings.json → hooks
~/.claude.json → mcpServers
```

### Project 범위 (.)
```
.claude/skills/*/SKILL.md
.claude/agents/*.md
.claude/settings.json → hooks
.mcp.json → mcpServers
```

### Local 범위
```
.claude/settings.local.json → hooks
```

### Plugins
```bash
claude plugin list 2>/dev/null
```

## 정보 수집

각 확장에 대해 다음 정보를 수집:

#### Skills
- `SKILL.md`의 frontmatter에서 `name`, `description`, `user-invocable` 파싱
- 호출 방법: `/<name>`

#### Agents
- `.md` 파일의 frontmatter에서 `name`, `description`, `model` 파싱

#### Hooks
- `settings.json`의 `hooks` 섹션에서 이벤트별 훅 목록
- 각 훅의 `type`, `matcher`, `command` 정보

#### MCP Servers
- `.mcp.json` 또는 `~/.claude.json`에서 서버 목록
- 각 서버의 `command`, `args` 정보

## 출력 형식

```
📦 설치된 Claude Code 확장 기능
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Skills (N개):
  [user]    /skill-1        - 설명...
  [project] /skill-2        - 설명...
  [plugin]  /plugin:skill-3 - 설명...

Agents (N개):
  [user]    agent-1 (sonnet)  - 설명...
  [project] agent-2 (haiku)   - 설명...

Hooks (N개):
  [user]    PreToolUse:Bash   - command: validate.sh
  [project] PostToolUse:Write - command: format.sh

MCP Servers (N개):
  [user]    github    - gh (stdio)
  [project] postgres  - npx @mcp/postgres (stdio)

Plugins (N개):
  [user]    plugin-1  - 활성화됨
  [project] plugin-2  - 비활성화됨

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
총 N개 확장 설치됨
```
