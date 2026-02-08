---
name: laravel-review
description: Laravel 코드를 CLAUDE.md 컨벤션 + Laravel 모범 사례 기준으로 리뷰합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<파일|디렉토리> [--focus <category>] [--fix]"
---

# Laravel Review - 라라벨 전용 코드 리뷰어

Laravel 코드를 CLAUDE.md 코딩 컨벤션과 Laravel 모범 사례 기준으로 리뷰합니다.
Gemini 불필요, Claude 단독으로 수행합니다.

## 인자 파싱

- `$ARGUMENTS`의 첫 번째 값: 대상 파일 또는 디렉토리 (필수)
- `--focus`: 특정 카테고리만 집중 리뷰
  - `structure` - guard clause, early return, 중첩 깊이
  - `performance` - N+1, 루프 내 쿼리, 컬렉션 최적화
  - `security` - SQL injection, XSS, mass assignment, CSRF
  - `architecture` - 책임 분리, fat controller, 비즈니스 로직 위치
- `--fix`: 리뷰 후 자동 수정까지 수행
- 인자 없음: 현재 디렉토리 또는 `git diff --cached` 대상

인자가 없으면:
```bash
# staged 파일이 있으면 staged 파일만 리뷰
STAGED=$(git diff --cached --name-only --diff-filter=ACMR -- '*.php' 2>/dev/null)

# 없으면 안내
# "리뷰 대상을 지정하세요. 예: /laravel-review app/Http/Controllers/"
```

## 리뷰 체크리스트

대상 파일을 Read 도구로 읽은 후, 아래 체크리스트를 순서대로 검사합니다.

### 1. 구조 (Structure)

- [ ] 조건문 중첩이 2단계를 넘는 곳 → guard clause / early return 제안
- [ ] else 절이 early return으로 제거 가능한 곳
- [ ] 하나의 메서드가 30줄을 넘으면 분리 제안
- [ ] Controller 메서드가 CRUD 외 비즈니스 로직을 직접 처리하는 곳 → Service/Action 분리 제안

```php
// 감지 패턴: 중첩 if
if ($condition1) {
    if ($condition2) {        // ← 2단계
        if ($condition3) {    // ← 3단계 → 위반
```

### 2. 퍼포먼스 (Performance)

- [ ] N+1 문제: 루프 안에서 관계 접근 (`$post->author`, `$order->items`) 시 `with()` 누락
- [ ] 루프 안 쿼리: `foreach` 내부에서 `::find()`, `::where()->first()`, `DB::` 호출
- [ ] `Model::all()` 사용: `chunk()`, `lazy()`, `select()` 필요 여부
- [ ] 컬렉션 비효율: `firstWhere()` 반복 → `keyBy()` 제안
- [ ] 컬렉션 체이닝: `filter()->map()->first()` 같은 다중 순회 감지
- [ ] `whereIn()`으로 대체 가능한 루프 + 개별 쿼리

```php
// 감지 패턴: 루프 내 쿼리
foreach ($ids as $id) {
    $user = User::find($id);  // ← 위반: whereIn으로 대체
}
```

### 3. 보안 (Security)

- [ ] Raw 쿼리에서 사용자 입력 직접 삽입 (`DB::raw("... $request->input ...")`)
- [ ] Mass assignment: `$request->all()` 직접 사용, `$fillable`/`$guarded` 미설정
- [ ] XSS: Blade에서 `{!! !!}` 사용 시 사용자 입력 포함 여부
- [ ] 인증/인가: 민감한 작업에 `authorize()`, `Gate`, `Policy` 누락
- [ ] 파일 업로드: 확장자/MIME 검증 없는 `store()`
- [ ] 환경 변수: 코드에 하드코딩된 API 키, 비밀번호, 시크릿

### 4. 아키텍처 (Architecture)

- [ ] Fat Controller: 컨트롤러에 비즈니스 로직 50줄 이상
- [ ] 모델에 쿼리 로직 대신 Scope 미사용
- [ ] Validation: Controller에서 인라인 검증 → FormRequest 분리 제안
- [ ] 반복 코드: 동일 쿼리/로직이 2곳 이상 → 재사용 가능한 구조 제안
- [ ] Route model binding 미사용: `User::find($id)` 대신 타입힌트 가능한 곳

## 리뷰 실행 프로세스

### 1단계: 대상 파일 수집

```bash
# 디렉토리면 PHP 파일 탐색
# Glob으로 "app/Http/Controllers/**/*.php" 등 수집
# git diff --cached 대상이면 staged PHP 파일만
```

### 2단계: 파일별 검사

각 파일을 Read로 읽고, 체크리스트 항목을 순서대로 검사합니다.

**--focus 옵션이 있으면** 해당 카테고리만 검사합니다.

### 3단계: 이슈 분류

각 이슈에 심각도를 부여합니다:

| 심각도 | 의미 | 예시 |
|--------|------|------|
| `critical` | 반드시 수정 | SQL injection, N+1 (대량 데이터) |
| `warning` | 수정 권장 | 중첩 3단계, fat controller |
| `suggestion` | 개선 제안 | keyBy 활용, FormRequest 분리 |

### 4단계: 리포트 출력

```
Laravel 코드 리뷰
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 app/Http/Controllers/OrderController.php

  🔴 [critical] 보안 - Mass Assignment (L:42)
     $order = Order::create($request->all());
     → $request->validated() 또는 $request->only([...]) 사용

  🟡 [warning] 구조 - 중첩 3단계 (L:58-82)
     if → if → if 중첩 발견
     → guard clause로 분리

  🟡 [warning] 퍼포먼스 - N+1 (L:95)
     foreach 내 $order->items 접근, with() 미사용
     → Order::with('items')->...

  🔵 [suggestion] 아키텍처 - FormRequest (L:35)
     인라인 validation 발견
     → OrderStoreRequest 분리 권장

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
리뷰 결과: 파일 3개 / 이슈 7개
  🔴 critical: 1  🟡 warning: 3  🔵 suggestion: 3
```

### 5단계: 자동 수정 (--fix 옵션)

`--fix`가 지정된 경우, `critical`과 `warning` 이슈를 자동 수정합니다:

1. 수정 전 현재 상태를 안내
2. Edit 도구로 파일 수정
3. 수정된 내용을 diff 형태로 표시
4. `suggestion`은 수정하지 않고 안내만

`--fix` 없으면 리포트만 출력하고 종료합니다.

## 사용 예시

```
/laravel-review app/Http/Controllers/              # 컨트롤러 전체 리뷰
/laravel-review app/Models/Order.php               # 특정 모델 리뷰
/laravel-review app/Services/ --focus performance   # 퍼포먼스만 집중
/laravel-review app/Http/ --fix                     # 리뷰 + 자동 수정
/laravel-review                                     # staged 파일 리뷰
```
