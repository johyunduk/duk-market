---
name: duo-review
description: "이미 구현된 코드에 대해 Gemini\u2194Claude 교차 검증 루프를 실행합니다. 기존 코드를 Gemini가 검증하고 Claude가 평가/수정합니다."
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "<파일경로 또는 설명> [--rounds <N>]"
---

# Duo Review - 기존 코드에 교차 검증 루프 실행

이미 작성된 코드에 대해 Gemini↔Claude 교차 검증을 실행합니다.
`/duo-loop`은 처음부터 분석→구현→검증이지만, `/duo-review`는 **기존 코드를 검증→수정**하는 데 집중합니다.

## 인자 파싱

- `$0`: 리뷰 대상 (파일 경로, 디렉토리, 또는 설명)
- `--rounds` 또는 `-r`: 최대 라운드 수 (기본: 3)
- `--focus`: 집중 영역 (bug, security, performance, quality)
- `--strict`: 엄격 모드 - suggestion도 수정 대상에 포함

## 루프 흐름

```
기존 코드 → 3️⃣ Gemini 검증 → 4️⃣ Claude 평가 → 수정 → 3️⃣ 재검증 → ... → 완료
```

`/duo-loop`의 Phase 1, 2를 건너뛰고 바로 Phase 3(Gemini 검증)부터 시작합니다.

### 1단계: 리뷰 대상 수집

```bash
# 파일 경로가 지정된 경우
CODE=$(cat $FILE_PATH)

# 디렉토리인 경우
CODE=$(find $DIR -name "*.ts" -o -name "*.js" | xargs cat)

# 설명만 있는 경우 - git diff 사용
CODE=$(git diff)
```

### 2단계: Gemini 검증

```bash
echo "$CODE" | gemini -p "
시니어 코드 리뷰어로서 이 코드를 검증하세요.

## 집중 영역: $FOCUS (또는 전체)

## 응답 형식
\`\`\`json
{
  \"verdict\": \"PASS\" | \"FAIL\",
  \"score\": 1-10,
  \"issues\": [
    {
      \"id\": 1,
      \"severity\": \"critical\" | \"warning\" | \"suggestion\",
      \"category\": \"bug\" | \"security\" | \"performance\" | \"quality\",
      \"file\": \"path\",
      \"line\": N,
      \"description\": \"설명\",
      \"suggestion\": \"수정 제안\"
    }
  ]
}
\`\`\`
"
```

### 3단계: Claude 평가 및 수정

Claude Code가 각 이슈를 평가:
- 코드를 직접 읽고 Gemini의 지적이 맞는지 확인
- 타당한 이슈만 수정
- 거부하는 이슈에는 근거 기록

### 4단계: 재검증 (라운드 반복)

수정된 코드를 다시 Gemini에게 보내 재검증. PASS 또는 최대 라운드까지 반복.

## 출력 형식

```
🔍 Duo Review: src/api/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Round 1/3:
  Gemini: FAIL (6/10) - 이슈 4개
  Claude: 수용 3 | 거부 1
  수정: auth.ts:23 SQL 인젝션, handler.ts:45 에러핸들링, ...

Round 2/3:
  Gemini: PASS (9/10) - 이슈 1개 (suggestion)
  루프 종료 ✅

최종: 6/10 → 9/10 📈 (+3)
수정된 파일: 2개
```

## 사용 예시

```
/duo-review src/api/                # 디렉토리 리뷰
/duo-review src/auth/login.ts       # 특정 파일 리뷰
/duo-review --focus security        # 보안 집중 리뷰
/duo-review src/ -r 5 --strict      # 엄격 모드 5라운드
```
