---
name: market-browse
description: Claude Code 확장 마켓플레이스에서 카테고리별로 확장 기능을 탐색합니다
user-invocable: true
allowed-tools: Bash, Read, WebFetch, WebSearch, Grep, Glob
argument-hint: "[category]"
---

# Claude Code Extensions Marketplace - Browse

사용자가 Claude Code 확장 기능을 카테고리별로 탐색할 수 있도록 도와주세요.

## 카테고리

확장 기능은 다음 카테고리로 분류됩니다:

| 카테고리 | 설명 | 파일 형식 |
|---------|------|----------|
| **skills** | 슬래시 커맨드, 도메인 지식, 워크플로우 | `SKILL.md` |
| **agents** | 특화된 서브에이전트 | `.md` (frontmatter) |
| **hooks** | 이벤트 기반 자동화 스크립트 | `hooks.json` + scripts |
| **mcp-servers** | 외부 도구/API 연동 | `.mcp.json` |
| **plugins** | 번들된 확장 패키지 | `plugin.json` + 구성요소 |

## 행동 지침

1. `$ARGUMENTS`가 비어있으면 전체 카테고리 목록을 보여주세요
2. `$ARGUMENTS`에 카테고리가 지정되면 해당 카테고리의 인기 확장 기능을 검색합니다

## 검색 방법

GitHub에서 Claude Code 확장 기능을 검색합니다:

```bash
# 카테고리별 검색 쿼리
gh search repos "claude-code skill SKILL.md" --sort stars --limit 20
gh search repos "claude-code plugin .claude-plugin" --sort stars --limit 20
gh search repos "claude-code hooks" --sort stars --limit 20
gh search repos "claude-code mcp server" --sort stars --limit 20
gh search repos "claude-code agent" --sort stars --limit 20
```

또한 다음 큐레이션 목록을 참고하세요:
- https://github.com/hesreallyhim/awesome-claude-code
- https://github.com/anthropics/claude-code

## 출력 형식

각 확장 기능을 다음 형식으로 표시하세요:

```
[카테고리] 이름
  설명: ...
  저자: ...
  Stars: ...
  설치: /market-install <repository-url>
```
