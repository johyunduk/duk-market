# duk-market

Claude Code 확장 마켓플레이스 + Gemini CLI 연동 플러그인.

확장 기능을 검색/설치/관리하고, Gemini CLI를 활용한 AI 협업 워크플로우를 제공합니다.

## 설치

```bash
claude plugin add johyunduk/duk-market
```

### Gemini CLI 연동 사전 준비 (선택)

Gemini 관련 기능을 사용하려면:

```bash
npm install -g @google/gemini-cli
gemini auth login
# 또는
export GEMINI_API_KEY="your-key"
```

## 마켓플레이스 기능

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

## Gemini CLI 연동 기능

분석은 Gemini, 구현은 Claude Code - 두 AI의 장점을 결합합니다.

### 분석 위임

Gemini가 분석/설계하고 Claude Code가 구현합니다:

```
/gemini-analyze 이 프로젝트에 사용자 인증 기능을 추가해줘
/gemini-analyze 현재 API의 성능 병목을 찾고 최적화해줘
/gemini-analyze 이 코드를 마이크로서비스로 리팩토링할 계획을 세워줘
```

### 코드 리뷰

Gemini가 리뷰하고 Claude Code가 수정합니다:

```
/gemini-review                      # staged/unstaged 변경 리뷰
/gemini-review src/auth/login.ts    # 특정 파일 리뷰
/gemini-review --pr 42              # PR 리뷰
```

### 기술 리서치

Gemini의 검색 능력으로 조사하고 Claude Code가 적용합니다:

```
/gemini-research Next.js 15 서버 컴포넌트에서 스트리밍 SSR 구현 방법
/gemini-research PostgreSQL 대용량 테이블 파티셔닝 전략
/gemini-research Docker compose에서 ECONNREFUSED 에러 해결
```

### 직접 질문

Gemini에게 직접 질문하고 second opinion을 받습니다:

```
/gemini-ask TypeScript 5.7의 새로운 기능은?
/gemini-ask React Server Components vs Next.js App Router 차이점
```

## 포함된 구성 요소

### Skills - 마켓플레이스

| 커맨드 | 설명 |
|--------|------|
| `/market-browse` | 카테고리별 확장 기능 탐색 |
| `/market-search` | 키워드로 확장 기능 검색 |
| `/market-install` | 확장 기능 설치 |
| `/market-uninstall` | 확장 기능 제거 |
| `/market-info` | 확장 기능 상세 정보 |
| `/market-list` | 설치된 확장 목록 |
| `/market-publish` | 확장 기능 배포/패키징 |

### Skills - Gemini 연동

| 커맨드 | 설명 |
|--------|------|
| `/gemini-analyze` | Gemini 분석 → Claude 구현 |
| `/gemini-review` | Gemini 리뷰 → Claude 수정 |
| `/gemini-research` | Gemini 리서치 → Claude 적용 |
| `/gemini-ask` | Gemini에게 직접 질문 |

### Agents

| 에이전트 | 설명 |
|---------|------|
| `marketplace` | 확장 탐색/설치 범용 에이전트 |
| `market-security` | 확장 보안 검토 에이전트 |
| `gemini-bridge` | Gemini CLI 연동 브릿지 에이전트 |

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
