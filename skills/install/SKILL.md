---
name: market-install
description: GitHub 레포지토리에서 Claude Code 확장 기능을 설치합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
argument-hint: "<repository> [--scope user|project|local]"
---

# Claude Code Extensions Marketplace - Install

GitHub 레포지토리에서 Claude Code 확장 기능을 현재 환경에 설치합니다.

## 인자 파싱

- `$0`: GitHub 레포지토리 (형식: `owner/repo` 또는 전체 URL)
- `--scope` 또는 `-s`: 설치 범위 - `user`(기본), `project`, `local`

예시:
- `/market-install anthropics/awesome-skill`
- `/market-install https://github.com/user/claude-mcp-server --scope project`
- `/market-install user/my-hooks -s local`

## 설치 프로세스

### 1단계: 레포지토리 분석

```bash
# 레포 클론 (임시 디렉토리)
TEMP_DIR=$(mktemp -d)
git clone --depth 1 "https://github.com/$REPO" "$TEMP_DIR"
```

레포지토리에서 다음 파일들을 확인:
- `.claude-plugin/plugin.json` → **플러그인** (번들)
- `skills/*/SKILL.md` → **스킬**
- `agents/*.md` → **에이전트**
- `hooks/hooks.json` → **훅**
- `.mcp.json` → **MCP 서버**
- `SKILL.md` (루트) → **단일 스킬**

### 2단계: 확장 유형별 설치

#### 플러그인인 경우 (.claude-plugin/ 존재)

```bash
claude plugin add "$REPO"
```

#### 단일 스킬인 경우 (SKILL.md)

scope에 따라 복사 위치 결정:
- `user`: `~/.claude/skills/<name>/`
- `project`: `.claude/skills/<name>/`
- `local`: `.claude/skills/<name>/` (+ .gitignore에 추가)

```bash
# 스킬 디렉토리 생성 및 복사
DEST="$SKILL_BASE/<skill-name>"
mkdir -p "$DEST"
cp -r "$TEMP_DIR/skills/<name>/"* "$DEST/" 2>/dev/null || cp "$TEMP_DIR/SKILL.md" "$DEST/"
```

#### 에이전트인 경우

```bash
DEST="$AGENT_BASE/"
cp "$TEMP_DIR/agents/"*.md "$DEST/"
```

#### MCP 서버인 경우

레포의 `.mcp.json`을 읽어서 현재 프로젝트 또는 사용자 설정에 병합:

```bash
# 프로젝트 .mcp.json에 서버 추가
# 기존 .mcp.json이 있으면 병합, 없으면 생성
```

#### 훅인 경우

레포의 `hooks/hooks.json`을 읽어서 설정에 병합:
- 스크립트 파일이 있으면 `~/.claude/hooks/` 또는 `.claude/hooks/`에 복사
- `settings.json`의 hooks 섹션에 추가

### 3단계: 의존성 설치

레포에 `package.json`이 있으면:
```bash
cd "$DEST" && npm install --production 2>/dev/null
```

### 4단계: 정리

```bash
rm -rf "$TEMP_DIR"
```

## 설치 확인

설치 후 확인 사항을 출력:

```
✅ 설치 완료: <extension-name>
   유형: skill | agent | hook | mcp-server | plugin
   범위: user | project | local
   위치: <설치 경로>

   사용법:
   - /skill-name (스킬인 경우)
   - 자동 로드됨 (에이전트/훅인 경우)
   - mcp__server__tool (MCP인 경우)
```

## 주의사항

- 설치 전 사용자에게 어떤 파일이 설치되는지 보여주고 확인을 받으세요
- 기존 파일을 덮어쓰기 전 반드시 경고하세요
- 훅의 경우 실행될 커맨드를 반드시 사용자에게 보여주고 승인받으세요 (보안)
- MCP 서버의 env에 API 키가 필요한 경우 사용자에게 안내하세요
