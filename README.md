# duk-market

Claude Code 올인원 플러그인 - 확장 마켓플레이스 + Gemini CLI 연동 + 로컬 메모리(SQLite) + 스키마(DDL) 관리 + 듀얼 AI 루프 + Laravel 코드 리뷰.

## 설치

```
/plugin marketplace add https://github.com/johyunduk/duk-market
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

### @gemini 자동 트리거

프롬프트에 `@gemini`를 포함하면 **자동으로 Gemini에게도 같은 질문**을 보내고, 양쪽 응답을 비교할 수 있습니다.

```
@gemini React 19의 새로운 use() 훅은 어떻게 쓰는거야?
이 코드 리팩토링 어떻게 하면 좋을까? @gemini
@gemini 이 에러 원인이 뭘까: Cannot read property of undefined
```

- 별도 커맨드 호출 없이 프롬프트에 `@gemini`만 넣으면 자동 작동
- Gemini 응답이 Claude 컨텍스트에 주입되어, Claude가 참고하여 답변
- Gemini CLI 미설치 시 안내 메시지 표시 (기존 Claude 응답에 영향 없음)

### 슬래시 커맨드 (수동)

```
/gemini-analyze 이 프로젝트에 인증 기능 추가해줘     # 분석→구현
/gemini-review src/auth/login.ts                     # 리뷰→수정
/gemini-research Next.js 15 스트리밍 SSR 방법         # 리서치→적용
/gemini-ask TypeScript 5.7 새 기능은?                 # 직접 질문
```

---

## 3. 로컬 메모리 시스템

세션에서 얻은 지식을 로컬 SQLite DB(`~/.claude/duk-market.db`)에 저장합니다.
claude-mem에서 영감을 받은 FTS5 전문 검색 기반 메모리 시스템입니다.

### 초기 설정

```bash
# DB 자동 초기화 (첫 사용 시 자동 실행됨)
# 또는 수동: bash scripts/init-db.sh
```

### 메모리 저장

```
/memory-save bugfix useEffect 무한 루프 - 의존성 배열에 객체 넣으면 발생
/memory-save pattern API 응답은 항상 { data, error, meta } 형태로 통일
/memory-save decision DB는 PostgreSQL 사용 - 이유: JSON 지원, 성숙한 생태계
/memory-save setup Docker compose 전에 .env.local 필요
/memory-save pitfall Next.js 서버 컴포넌트에서 useState 사용 불가
/memory-save 오늘 배운 것: Git rebase vs merge 차이   # 카테고리 자동 분류
```

### 메모리 검색 (FTS5)

```
/memory-recall useEffect                    # 전문 검색
/memory-recall react -c bugfix              # 카테고리 필터
/memory-recall docker -r 7                  # 최근 7일 이내
/memory-recall --id 42                      # ID로 상세 보기
```

### 메모리 관리

```
/memory-list                # 전체 목록
/memory-list --stats        # 통계 (카테고리별, 프로젝트별)
/memory-remove 42           # ID로 삭제
/memory-remove -c til       # 카테고리 전체 삭제
/memory-summary             # 현재 세션 요약 저장
```

### DB 구조

```
~/.claude/duk-market.db
├── memories      # 지식 저장 (FTS5 인덱싱)
├── schemas       # DDL 영구 저장 (버전 이력 관리)
├── observations  # 자동 캡처된 도구 사용 기록
├── sessions      # 세션 요약
└── duo_loops     # Duo Loop 상태
```

### 스키마(DDL) 영구 저장

테이블 DDL을 **만료 없이 영구 보관**합니다. 일반 memories와 분리된 `schemas` 테이블에서 버전 이력을 관리합니다.

```
/schema-save CREATE TABLE users (id INT PRIMARY KEY, name TEXT, email TEXT UNIQUE)
/schema-save ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'
```

```
/schema-list                    # 현재 프로젝트 테이블 현황 (최신 버전만)
/schema-history users           # users 테이블의 v1→v2→v3 변경 이력
```

- Bash에서 DDL 실행 시 **자동 감지/저장** (PostToolUse 훅)
- `/schema-save`로 수동 저장도 가능
- 세션 시작 시 컨텍스트에 주입하지 않음 (온디맨드 조회)

### 자동 동작 (Hooks) - 수동 저장 불필요

모든 메모리 캡처가 자동으로 이루어집니다:

- **PostToolUse** (Write/Edit/Bash): 파일 수정, 명령 실행을 `observations` 테이블에 자동 기록 + DDL 감지 시 `schemas` 테이블에 영구 저장 (async)
- **세션 종료 (Stop)**:
  1. `auto-summary.sh`가 세션 요약을 `sessions` 테이블에 자동 저장 + 오래된 데이터 정리
  2. agent 훅이 관찰 내용을 분석하여 중요한 것만 `memories` 테이블에 자동 INSERT (importance=3)
- **세션 시작 (SessionStart)**: `load-context.sh`가 DB에서 직접 쿼리하여 zero-turn 컨텍스트 주입
  - 이전 세션 요약 (최근 1건)
  - 주요 결정사항 (최근 5건)
  - 주의사항 (최근 5건)
  - 최근 버그 수정 (7일 이내, 3건)
  - 중단된 Duo Loop 감지

`/memory-save`로 수동 저장도 가능하며, 수동 저장은 importance=5로 영구 보관됩니다.

### 중요도 및 자동 만료

| importance | 저장 방식 | 만료 정책 |
|-----------|----------|----------|
| 5 | 수동 (`/memory-save`) | 영구 보관 |
| 3 | 자동 (Stop 훅) | `til` 카테고리만 90일 후 자동 삭제 |
| - | `decision`, `pitfall` | 중요도 무관 영구 보관 |

### 자동 정리 (Stop 훅)

- 완료된 세션의 observations 자동 삭제
- 30일 이상 된 observations 자동 삭제
- sessions 테이블 최근 50건만 유지
- importance ≤ 3인 `til` 카테고리 메모리 90일 후 자동 만료

---

## 4. Duo Loop - 듀얼 AI 교차 검증 루프

Ralph Wiggum의 자기 참조 루프에서 영감을 받아, **Gemini와 Claude가 서로를 검증**하는 반복 루프입니다.

```
Gemini 분석 → Claude 구현 → Gemini 검증 → Claude 평가/수정 → 재검증 → ... → 완료
```

### 전체 루프 실행

```
/duo-loop 사용자 인증 API를 JWT 기반으로 구현해줘
/duo-loop 결제 시스템에 Stripe 연동 추가
/duo-loop 테스트 커버리지 80% 이상으로 올려줘
```

### 기존 코드 검증 루프

```
/duo-review src/api/                # 디렉토리 교차 검증
/duo-review src/auth/login.ts       # 특정 파일
/duo-review --focus security        # 보안 집중
/duo-review src/ -r 5 --strict      # 엄격 모드 5라운드
```

### 상태 확인

```
/duo-status            # 현재 루프 상태
/duo-status --history  # 루프 히스토리
```

### 루프 동작 방식

각 라운드에서:

1. **Gemini 검증**: 코드를 `gemini -p`로 보내 JSON 형식의 리뷰 결과 수신
2. **Claude 평가**: 각 이슈를 코드에서 직접 확인
   - **수용**: 실제 문제 → 수정 진행
   - **거부**: 오탐(false positive) → 근거와 함께 기각
   - **보류**: 현재 스코프 밖 → 나중에 처리
3. **수정**: 수용한 이슈를 Claude가 수정
4. **재검증**: 수정된 코드를 Gemini에게 다시 전달

**종료 조건**: Gemini가 PASS 판정 (8/10 이상) 또는 최대 라운드 도달

```
🏁 Duo Loop 완료
━━━━━━━━━━━━━━━
작업: JWT 인증 구현
라운드: 3/5
점수: 6 → 8 → 9 📈
수정: 5개 수용, 2개 거부
```

---

## 5. Laravel 코드 리뷰

CLAUDE.md 코딩 컨벤션 + Laravel 모범 사례 기준으로 코드를 리뷰합니다. Gemini 불필요, Claude 단독 수행.

### 리뷰 카테고리

| 카테고리 | 검사 항목 |
|----------|----------|
| `structure` | 중첩 if → guard clause / early return, 긴 메서드 분리 |
| `performance` | N+1, 루프 내 쿼리, `all()`, `firstWhere()` 반복, 컬렉션 다중 순회 |
| `security` | SQL injection, mass assignment, XSS, 인증/인가 누락 |
| `architecture` | fat controller, FormRequest 미분리, scope 미사용, route model binding |

### 사용법

```
/laravel-review app/Http/Controllers/              # 컨트롤러 전체 리뷰
/laravel-review app/Models/Order.php               # 특정 모델
/laravel-review app/Services/ --focus performance   # 퍼포먼스만 집중
/laravel-review app/Http/ --fix                     # 리뷰 + 자동 수정
/laravel-review                                     # staged 파일 리뷰
```

### 심각도

- `critical` - 반드시 수정 (SQL injection, N+1 대량 데이터)
- `warning` - 수정 권장 (중첩 3단계, fat controller)
- `suggestion` - 개선 제안 (keyBy 활용, FormRequest 분리)

`--fix` 옵션 사용 시 `critical`/`warning` 이슈를 자동 수정합니다.

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
| `/memory-save` | SQLite에 지식 저장 |
| `/memory-recall` | FTS5 전문 검색 |
| `/memory-list` | 메모리 목록/통계 |
| `/memory-remove` | 메모리 삭제 |
| `/memory-summary` | 세션 요약 저장 |
| `/schema-save` | DDL 영구 저장 (버전 자동 관리) |
| `/schema-list` | 프로젝트 스키마 현황 조회 |
| `/schema-history` | 테이블별 DDL 변경 이력 |
| `/laravel-review` | Laravel 전용 코드 리뷰 (구조/퍼포먼스/보안/아키텍처) |
| `/duo-loop` | Gemini↔Claude 전체 루프 (분석→구현→검증→수정) |
| `/duo-review` | 기존 코드에 교차 검증 루프 실행 |
| `/duo-status` | 루프 진행 상태/히스토리 확인 |

### Agents

| 에이전트 | 설명 |
|---------|------|
| `marketplace` | 확장 탐색/설치 범용 에이전트 |
| `market-security` | 확장 보안 검토 에이전트 |
| `gemini-bridge` | Gemini CLI 연동 브릿지 에이전트 |
| `memory-manager` | SQLite 메모리 정리/품질 관리/CLAUDE.md 연동 에이전트 |
| `duo-loop` | Gemini↔Claude 교차 검증 루프 관리 에이전트 |

### Hooks

| 이벤트 | 타입 | 설명 |
|--------|------|------|
| `UserPromptSubmit` | command | `auto-gemini.sh` - `@gemini` 키워드 감지 시 자동 Gemini 호출 |
| `PreToolUse:Bash` | prompt | 외부 확장 설치 시 보안 패턴 검증 |
| `PostToolUse:Write\|Edit\|Bash` | command (async) | 도구 사용 기록 자동 캡처 + DDL 감지 시 schemas에 영구 저장 |
| `SessionStart` | command | `load-context.sh` - DB에서 직접 쿼리, zero-turn 컨텍스트 주입 |
| `Stop` | command + agent | 세션 요약 저장 + 데이터 정리 + 조건부 메모리 자동 INSERT |

## 라이선스

MIT
