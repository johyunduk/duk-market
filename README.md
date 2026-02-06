# duk-market

Claude Code 확장 마켓플레이스 플러그인.

Skills, Agents, Hooks, MCP Servers, Plugins를 검색하고 설치할 수 있는 Claude Code 플러그인입니다.

## 설치

```bash
claude plugin add johyunduk/duk-market
```

## 사용법

### 확장 기능 탐색

```
/market-browse              # 전체 카테고리 보기
/market-browse skills       # 스킬 카테고리 탐색
/market-browse mcp-servers  # MCP 서버 탐색
```

### 확장 기능 검색

```
/market-search git hooks               # 키워드 검색
/market-search linter -c skills        # 카테고리 필터
/market-search deploy --sort updated   # 최근 업데이트순
```

### 확장 기능 설치

```
/market-install owner/repo                   # GitHub 레포에서 설치
/market-install owner/repo --scope project   # 프로젝트 범위로 설치
/market-install owner/repo -s user           # 사용자 범위로 설치
```

### 확장 기능 상세 정보

```
/market-info owner/repo     # 원격 레포 정보
/market-info skill-name     # 로컬 설치된 확장 정보
```

### 설치된 확장 목록

```
/market-list                   # 전체 목록
/market-list --type skills     # 스킬만 보기
/market-list --scope project   # 프로젝트 범위만 보기
```

### 확장 기능 제거

```
/market-uninstall extension-name
/market-uninstall extension-name --scope project
```

### 확장 기능 배포

```
/market-publish              # 현재 프로젝트를 확장으로 패키징
/market-publish --type skill # 스킬로 패키징
```

## 포함된 구성 요소

### Skills

| 커맨드 | 설명 |
|--------|------|
| `/market-browse` | 카테고리별 확장 기능 탐색 |
| `/market-search` | 키워드로 확장 기능 검색 |
| `/market-install` | 확장 기능 설치 |
| `/market-uninstall` | 확장 기능 제거 |
| `/market-info` | 확장 기능 상세 정보 |
| `/market-list` | 설치된 확장 목록 |
| `/market-publish` | 확장 기능 배포/패키징 |

### Agents

| 에이전트 | 설명 |
|---------|------|
| `marketplace` | 복잡한 확장 탐색/설치 작업을 처리하는 범용 에이전트 |
| `market-security` | 확장 기능의 보안을 검토하는 전문 에이전트 |

### Hooks

| 이벤트 | 설명 |
|--------|------|
| `PreToolUse:Bash` | 외부 확장 설치 시 보안 패턴 검증 |

## 지원하는 확장 유형

| 유형 | 파일 | 설명 |
|------|------|------|
| **Skill** | `SKILL.md` | 슬래시 커맨드, 도메인 지식 |
| **Agent** | `*.md` (frontmatter) | 특화된 서브에이전트 |
| **Hook** | `hooks.json` + scripts | 이벤트 기반 자동화 |
| **MCP Server** | `.mcp.json` | 외부 도구/API 연동 |
| **Plugin** | `.claude-plugin/` | 번들된 확장 패키지 |

## 라이선스

MIT
