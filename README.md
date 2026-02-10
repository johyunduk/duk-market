# duk-market

Claude Code 플러그인 모음 - 필요한 것만 골라서 설치하세요.

## 설치 방법

**1단계 — 마켓플레이스 등록 (최초 1회)**

```
/plugin marketplace add https://github.com/johyunduk/duk-market
```

**2단계 — 플러그인 설치 (필요한 것만)**

```
/plugin install duk-gemini-duo
/plugin install duk-memory
/plugin install duk-laravel
```

---

## 플러그인 목록

| 플러그인 | 설명 |
|---------|------|
| [duk-gemini-duo](#1-duk-gemini-duo) | Gemini CLI 연동 + 듀얼 AI 루프 |
| [duk-memory](#2-duk-memory) | 로컬 메모리 + 스키마(DDL) 관리 |
| [duk-laravel](#3-duk-laravel) | Laravel 코드 리뷰 |

---

## 1. duk-gemini-duo

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

### Duo Loop - 듀얼 AI 교차 검증 루프

```
Gemini 분석 → Claude 구현 → Gemini 검증 → Claude 평가/수정 → 재검증 → ... → 완료
```

```
/duo-loop 사용자 인증 API를 JWT 기반으로 구현해줘
/duo-loop 결제 시스템에 Stripe 연동 추가

/duo-review src/api/                # 기존 코드 교차 검증
/duo-review --focus security        # 보안 집중
/duo-review src/ -r 5 --strict      # 엄격 모드 5라운드

/duo-status            # 현재 루프 상태
/duo-status --history  # 루프 히스토리
```

각 라운드에서 Gemini가 JSON 피드백(점수 1-10 + 이슈 목록)을 주면, Claude가 각 이슈를 수용/거부/보류로 평가 후 수정합니다. Gemini 점수 8/10 이상 또는 최대 라운드 도달 시 종료됩니다.

---

## 2. duk-memory

세션에서 얻은 지식을 로컬 SQLite DB에 저장합니다. 데이터는 `~/.claude/duk-market.db`에 영구 보관됩니다.

### 사전 준비

플러그인 설치 후 **최초 1회** 훅 등록이 필요합니다.

```bash
~/.claude/plugins/cache/duk-market/duk-memory/0.1.0/scripts/setup.sh
```

> 이 스크립트가 `~/.claude/settings.json`에 PostToolUse/SessionStart 훅을 자동 등록합니다.

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

### 스키마(DDL) 영구 저장

```
/schema-save CREATE TABLE users (id INT PRIMARY KEY, name TEXT, email TEXT UNIQUE)
/schema-save ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'

/schema-list                    # 현재 프로젝트 테이블 현황 (최신 버전만)
/schema-history users           # users 테이블의 v1→v2→v3 변경 이력
```

- Bash에서 DDL 실행 시 **자동 감지/저장** (PostToolUse 훅)
- 세션 시작 시 이전 요약/결정사항/버그 수정이 자동으로 컨텍스트에 주입됨

### 중요도 및 자동 만료

| importance | 저장 방식 | 만료 정책 |
|-----------|----------|----------|
| 5 | 수동 (`/memory-save`) | 영구 보관 |
| 3 | 자동 (Stop 훅) | `til` 카테고리만 90일 후 자동 삭제 |
| - | `decision`, `pitfall` | 중요도 무관 영구 보관 |

---

## 3. duk-laravel

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

## 라이선스

MIT


