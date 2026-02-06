# duk-market

Claude Code 올인원 플러그인 - 확장 마켓플레이스 + Gemini CLI 연동 + 공유 메모리 시스템.

## 설치

```bash
claude plugin add johyunduk/duk-market
```

---

## 1. 마켓플레이스

Claude Code 확장 기능(Skills, Agents, Hooks, MCP Servers, Plugins)을 검색하고 설치합니다.

```
/market-browse              # 카테고리별 탐색
/market-browse skills       # 스킬만 탐색

/market-search git hooks               # 키워드 검색
/market-search linter -c skills        # 카테고리 필터

/market-install owner/repo                   # GitHub에서 설치
/market-install owner/repo --scope project   # 프로젝트 범위로 설치

/market-info owner/repo     # 상세 정보
/market-list                # 설치된 확장 목록
/market-uninstall name      # 제거
/market-publish             # 내 확장을 패키징/공유
```

---

## 2. Gemini CLI 연동

분석은 Gemini, 구현은 Claude Code - 두 AI의 장점을 결합합니다.

### 사전 준비

```bash
npm install -g @google/gemini-cli
gemini auth login  # 또는 export GEMINI_API_KEY="your-key"
```

### 사용법

```
/gemini-analyze 이 프로젝트에 인증 기능 추가해줘     # 분석→구현
/gemini-review src/auth/login.ts                     # 리뷰→수정
/gemini-research Next.js 15 스트리밍 SSR 방법         # 리서치→적용
/gemini-ask TypeScript 5.7 새 기능은?                 # 직접 질문
```

---

## 3. 공유 메모리 시스템

세션에서 얻은 지식을 마크다운 파일로 저장하고, Git으로 팀과 공유합니다.
claude-mem에서 영감을 받았지만, SQLite 대신 **마크다운 파일 기반**으로 Git 친화적입니다.

### 메모리 저장

```
/memory-save bugfix useEffect 무한 루프 - 의존성 배열에 객체 넣으면 발생
/memory-save pattern API 응답은 항상 { data, error, meta } 형태로 통일
/memory-save decision DB는 PostgreSQL 사용 - 이유: JSON 지원, 성숙한 생태계
/memory-save setup Docker compose 전에 .env.local 필요
/memory-save pitfall Next.js 서버 컴포넌트에서 useState 사용 불가
/memory-save snippet 재사용 가능한 fetch wrapper 코드
/memory-save 오늘 배운 것: Git rebase vs merge 차이   # 카테고리 자동 분류
```

### 메모리 검색

```
/memory-recall useEffect                    # 키워드 검색
/memory-recall react -c bugfix              # 카테고리 필터
/memory-recall -a johyunduk                 # 작성자 필터
/memory-recall docker -r 7                  # 최근 7일 이내
```

### 메모리 관리

```
/memory-list                # 전체 목록
/memory-list --stats        # 통계 (카테고리별, 작성자별)
/memory-remove old-memo     # 삭제
/memory-summary             # 현재 세션 요약 저장
```

### 메모리 공유

```
/memory-share               # 새 메모리를 Git 커밋
/memory-share --push        # 커밋 + 푸시
/memory-share --export ~/backup/memories    # 내보내기
/memory-share --import ../other-project/.claude/memories  # 가져오기
```

### 메모리 저장 구조

```
.claude/memories/
├── decision/    # 아키텍처/설계 결정사항
├── bugfix/      # 버그 수정 기록과 원인
├── pattern/     # 코드 패턴, 관례
├── setup/       # 환경 설정, 설치 절차
├── pitfall/     # 주의사항
├── snippet/     # 코드 스니펫
├── til/         # Today I Learned
├── session/     # 세션 요약 (자동)
└── local/       # 개인 메모 (gitignored)
```

### 자동 동작 (Hooks)

- **세션 시작**: 최근 세션 요약과 주요 메모리(decision, pitfall)를 자동으로 컨텍스트에 주입
- **세션 종료**: 중요한 작업이 있었다면 `/memory-save`로 저장할 것을 제안

---

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
| `/gemini-analyze` | Gemini 분석 → Claude 구현 |
| `/gemini-review` | Gemini 리뷰 → Claude 수정 |
| `/gemini-research` | Gemini 리서치 → Claude 적용 |
| `/gemini-ask` | Gemini에게 직접 질문 |
| `/memory-save` | 지식/결정사항 저장 |
| `/memory-recall` | 메모리 검색 |
| `/memory-list` | 메모리 목록/통계 |
| `/memory-share` | Git으로 메모리 공유 |
| `/memory-remove` | 메모리 삭제 |
| `/memory-summary` | 세션 요약 저장 |

### Agents

| 에이전트 | 설명 |
|---------|------|
| `marketplace` | 확장 탐색/설치 범용 에이전트 |
| `market-security` | 확장 보안 검토 에이전트 |
| `gemini-bridge` | Gemini CLI 연동 브릿지 에이전트 |
| `memory-manager` | 메모리 정리/품질 관리/CLAUDE.md 연동 에이전트 |

### Hooks

| 이벤트 | 설명 |
|--------|------|
| `PreToolUse:Bash` | 외부 확장 설치 시 보안 패턴 검증 |
| `SessionStart` | 세션 시작 시 관련 메모리 컨텍스트 주입 |
| `Stop` | 세션 종료 시 메모리 저장 제안 |

## 라이선스

MIT
