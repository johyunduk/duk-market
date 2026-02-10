# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 프로젝트 개요

**duk-market**은 Claude Code 올인원 플러그인입니다. 확장 마켓플레이스, Gemini CLI 연동, 로컬 SQLite 메모리, DDL 버전 관리, 듀얼 AI 루프, Laravel 코드 리뷰를 하나의 패키지로 제공합니다.

- **언어:** Bash (자동화 스크립트), Markdown (스킬/에이전트 정의)
- **DB:** SQLite (`~/.claude/duk-market.db`) — FTS5 전문 검색 포함
- **외부 의존성:** Google Gemini CLI (Gemini 기능 사용 시)

---

## 주요 커맨드

### 플러그인 설치

```
/plugin marketplace add https://github.com/johyunduk/duk-market
```

### DB 초기화 (수동)

```bash
bash scripts/init-db.sh
```

### Gemini CLI 설치 (Gemini/Duo 기능 사전 준비)

```bash
npm install -g @google/gemini-cli
gemini auth login  # 또는 export GEMINI_API_KEY="your-key"
```

---

## 아키텍처

### 디렉토리 구조

```
duk-market/
├── .claude-plugin/
│   ├── plugin.json          # 플러그인 메타데이터 (진입점: skills/, agents/, hooks/)
│   └── marketplace.json     # 큐레이션된 확장 카탈로그
├── skills/                  # 23개 슬래시 커맨드 정의 (각 디렉토리당 SKILL.md)
├── agents/                  # 5개 전문 서브에이전트 (marketplace, gemini-bridge, memory-manager, duo-loop, security-reviewer)
├── hooks/
│   └── hooks.json           # 이벤트 기반 자동화 트리거
└── scripts/                 # 훅에서 호출되는 Bash 자동화
    ├── init-db.sh            # SQLite 스키마 초기화
    ├── auto-gemini.sh        # @gemini 키워드 감지 → Gemini CLI 호출
    ├── auto-observe.sh       # 도구 사용 이벤트 캡처 (async)
    ├── auto-summary.sh       # 세션 요약 생성
    └── load-context.sh       # 세션 시작 시 zero-turn 컨텍스트 주입
```

### 데이터 흐름

훅이 전체 자동화의 핵심입니다:

| 이벤트 | 스크립트/핸들러 | 동작 |
|--------|----------------|------|
| `UserPromptSubmit` | `auto-gemini.sh` | `@gemini` 키워드 감지 → Gemini 호출 → Claude 컨텍스트 주입 |
| `PreToolUse:Bash` | prompt 훅 | 외부 확장 설치 명령 보안 패턴 검증 |
| `PostToolUse:Write\|Edit\|Bash` | `auto-observe.sh` (async) | observations 테이블 기록 + DDL 감지 시 schemas 테이블 영구 저장 |
| `SessionStart` | `load-context.sh` | DB 쿼리로 이전 세션 요약/결정사항/버그/중단된 Duo Loop 주입 |
| `Stop` | `auto-summary.sh` + memory agent | 세션 요약 → sessions 테이블 + 중요 관찰 → memories 테이블 (importance=3) |

### SQLite DB 스키마 (`~/.claude/duk-market.db`)

| 테이블 | 목적 | 만료 정책 |
|--------|------|----------|
| `memories` | 지식 스니펫 (FTS5 인덱싱) | 수동 저장(importance=5) 영구 / 자동 저장(importance=3) `til` 카테고리 90일 후 삭제 / `decision`, `pitfall` 카테고리 영구 |
| `sessions` | 세션 요약 | 최근 50건 유지 |
| `schemas` | DDL 버전 이력 | 만료 없음 (영구) |
| `observations` | 도구 사용 이벤트 | 세션 종료 시 또는 30일 후 삭제 |
| `duo_loops` | Duo Loop 상태 추적 | — |

---

## 스킬/에이전트 추가 방법

- **스킬:** `skills/<name>/SKILL.md` 파일 생성 후 `plugin.json`의 `skills` 경로 확인
- **에이전트:** `agents/<name>.md` 파일 생성 후 `plugin.json`의 `agents` 경로 확인
- 훅 추가 시 `hooks/hooks.json` 수정 (command 타입은 스크립트 경로, prompt 타입은 지시문 직접 포함)

---

## 코딩 컨벤션 (Laravel)

`/laravel-review` 스킬이 아래 기준으로 코드를 리뷰합니다.

### 구조

- 중첩 if 대신 guard clause / early return 우선 사용
- 조건문 중첩이 2단계를 넘으면 반드시 early return으로 분리

```php
// bad
public function update(Request $request, $id)
{
    if ($request->has('name')) {
        $user = User::find($id);
        if ($user) {
            if ($user->isActive()) {
                $user->update(['name' => $request->name]);
                return response()->json($user);
            } else {
                return response()->json(['error' => 'inactive'], 403);
            }
        } else {
            return response()->json(['error' => 'not found'], 404);
        }
    }
    return response()->json(['error' => 'invalid'], 400);
}

// good
public function update(Request $request, $id)
{
    if (!$request->has('name')) {
        return response()->json(['error' => 'invalid'], 400);
    }

    $user = User::find($id);
    if (!$user) {
        return response()->json(['error' => 'not found'], 404);
    }

    if (!$user->isActive()) {
        return response()->json(['error' => 'inactive'], 403);
    }

    $user->update(['name' => $request->name]);
    return response()->json($user);
}
```

### 퍼포먼스

**Eloquent / 쿼리**

- N+1 문제 방지: 관계 데이터 접근 시 `with()` eager loading 필수
- 대량 데이터 처리 시 `chunk()` 또는 `lazy()` 사용, `all()` 지양
- 필요한 컬럼만 `select()`, 전체 컬럼 조회 지양
- 루프 안에서 쿼리 실행 금지 — 루프 밖에서 일괄 조회 후 처리
- `whereIn()`으로 해결 가능한 경우 루프 + 개별 쿼리 사용 금지

```php
// bad - N+1
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name;
}

// good
$posts = Post::with('author')->select('id', 'title', 'author_id')->get();
```

**컬렉션 / 루프**

- `Collection` 메서드 체이닝 시 순회 횟수 인지 (`filter→map→first`는 3회 순회)
- 검색/존재 확인은 `keyBy()` 또는 `pluck()->flip()`으로 O(1) 접근 고려
- 동일 계산 반복하지 말 것 — 루프 밖으로 이동

```php
// bad - O(n) 매번 탐색
foreach ($orders as $order) {
    $user = $users->firstWhere('id', $order->user_id);
}

// good - O(1) 조회
$userMap = $users->keyBy('id');
foreach ($orders as $order) {
    $user = $userMap[$order->user_id] ?? null;
}
```

**일반**

- 불필요한 배열 복사 최소화
- 캐싱 가능한 값은 `Cache::remember()` 활용
- 무거운 작업은 Queue/Job으로 분리
