---
name: market-uninstall
description: 설치된 Claude Code 확장 기능을 제거합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "<extension-name> [--scope user|project|local]"
---

# Claude Code Extensions Marketplace - Uninstall

설치된 Claude Code 확장 기능을 안전하게 제거합니다.

## 인자 파싱

- `$0`: 제거할 확장 이름
- `--scope` 또는 `-s`: 검색 범위 - 지정하지 않으면 모든 범위에서 검색
- `--force` 또는 `-f`: 확인 없이 제거

## 제거 프로세스

### 1단계: 설치된 확장 찾기

다음 위치에서 해당 이름의 확장을 검색:

```
검색 순서:
1. ~/.claude/skills/<name>/
2. .claude/skills/<name>/
3. ~/.claude/agents/<name>.md
4. .claude/agents/<name>.md
5. settings.json 내 hooks
6. .mcp.json 내 서버
7. 설치된 plugins (claude plugin list)
```

### 2단계: 제거 대상 확인

```
제거 대상:
━━━━━━━━━━━━━━━━━━━━━━
이름: <extension-name>
유형: skill | agent | hook | mcp-server | plugin
범위: user | project | local
위치: <경로>
파일:
  - file1.md
  - file2.sh

정말 제거하시겠습니까? (--force로 건너뛰기 가능)
```

### 3단계: 유형별 제거

#### 플러그인

```bash
claude plugin uninstall <name>
```

#### 스킬

```bash
rm -rf "$SKILL_BASE/<name>/"
```

#### 에이전트

```bash
rm "$AGENT_BASE/<name>.md"
```

#### MCP 서버

`.mcp.json` 또는 `~/.claude.json`에서 해당 서버 항목 제거

#### 훅

`settings.json`에서 해당 훅 항목 제거. 관련 스크립트 파일도 제거.

### 4단계: 정리 확인

```
✅ 제거 완료: <extension-name>
   제거된 파일: N개
   설정 변경: settings.json에서 hook 제거됨
```

## 주의사항

- 제거 전 반드시 사용자 확인 (--force 없는 한)
- 다른 확장이 의존하는 경우 경고
- 설정 파일 변경 시 백업 안내
