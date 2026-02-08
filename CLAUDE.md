# 코딩 컨벤션 (Laravel)

## 구조

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

## 퍼포먼스

### Eloquent / 쿼리

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

### 컬렉션 / 루프

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

### 일반

- 불필요한 배열 복사 최소화
- 캐싱 가능한 값은 `Cache::remember()` 활용
- 무거운 작업은 Queue/Job으로 분리
