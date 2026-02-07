---
name: duo-loop
description: "Gemini\u2194Claude 듀얼 AI 루프 - Ralph Wiggum 스타일의 반복 검증. Gemini가 분석하고 Claude가 구현한 뒤, Gemini가 검증하고 Claude가 평가/수정하는 루프를 문제가 해결될 때까지 반복합니다."
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
argument-hint: "<구현할 작업 설명>"
---

# Duo Loop - Gemini↔Claude 듀얼 AI 반복 검증 루프

Ralph Wiggum 패턴에서 영감을 받은 **듀얼 AI 교차 검증 루프**입니다.
하나의 AI가 자기 작업을 검증하는 대신, **Gemini와 Claude가 서로를 검증**합니다.

## 루프 흐름

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  1️⃣  Gemini 분석                                    │
│     └→ 작업 분석, 구현 계획, 핵심 로직 설계          │
│                                                     │
│  2️⃣  Claude 구현                                    │
│     └→ Gemini의 분석을 바탕으로 실제 코드 작성       │
│                                                     │
│  3️⃣  Gemini 검증                                    │
│     └→ Claude의 구현을 리뷰, 버그/개선점 목록 생성   │
│                                                     │
│  4️⃣  Claude 평가                                    │
│     └→ Gemini의 지적이 타당한지 판단                 │
│         ├→ 타당함 → 5️⃣ 수정 후 3️⃣으로 돌아감        │
│         └→ 부당함 → 반박 근거 기록, 무시             │
│                                                     │
│  5️⃣  완료 판정                                      │
│     └→ 더 이상 유효한 이슈가 없으면 루프 종료        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## 상세 프로세스

### Phase 1: Gemini 분석 (초기)

```bash
# 프로젝트 컨텍스트 수집
PROJECT_TREE=$(find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.next/*' | head -80)

# 관련 파일이 있으면 내용도 포함
RELEVANT_CODE=$(관련 파일 내용)

gemini -p "
당신은 시니어 소프트웨어 아키텍트입니다.

## 작업
$ARGUMENTS

## 프로젝트 구조
$PROJECT_TREE

## 관련 코드
$RELEVANT_CODE

## 요청
다음 형식으로 구현 계획을 작성해주세요:

### 분석
(요구사항 분석)

### 구현 계획
1. 파일: path/to/file.ts
   변경: (구체적 변경 내용)
2. ...

### 핵심 로직
(pseudocode 또는 알고리즘)

### 예상 엣지 케이스
- case 1
- case 2
"
```

Gemini의 응답을 `GEMINI_ANALYSIS` 변수에 저장합니다.

### Phase 2: Claude 구현

Gemini의 분석 결과를 참고하여 Claude Code가 **실제 코드를 작성**합니다.
- Gemini가 제안한 파일별 변경 사항을 순서대로 구현
- 핵심 로직을 실제 코드로 변환
- 예상 엣지 케이스 처리

구현 완료 후 변경 사항을 기록합니다:

```bash
# 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only)

# 변경 내용
CHANGES_DIFF=$(git diff)
```

### Phase 3: Gemini 검증 (루프 핵심)

Claude의 구현을 Gemini에게 보내서 검증합니다:

```bash
(echo "=== 변경된 파일 ===" && git diff) | gemini -p "
당신은 시니어 코드 리뷰어입니다.
다음 코드 변경을 꼼꼼하게 리뷰하세요.

## 원래 작업 요구사항
$ARGUMENTS

## 초기 분석
$GEMINI_ANALYSIS

## 구현된 코드 변경 (diff)
(stdin으로 전달됨)

## 검증 항목
다음 각 항목에 대해 PASS 또는 FAIL로 판정하세요:

1. **기능 완성도**: 요구사항이 모두 구현되었는가?
2. **버그**: 로직 오류, 엣지 케이스 미처리, null/undefined 위험?
3. **보안**: 인젝션, XSS, 인증 문제?
4. **성능**: 불필요한 연산, 메모리 누수?
5. **코드 품질**: 네이밍, 구조, 가독성?

## 응답 형식
반드시 다음 JSON 형식으로 응답하세요:

\`\`\`json
{
  \"verdict\": \"PASS\" | \"FAIL\",
  \"score\": 1-10,
  \"issues\": [
    {
      \"id\": 1,
      \"severity\": \"critical\" | \"warning\" | \"suggestion\",
      \"category\": \"bug\" | \"security\" | \"performance\" | \"quality\" | \"completeness\",
      \"file\": \"path/to/file.ts\",
      \"line\": 42,
      \"description\": \"문제 설명\",
      \"suggestion\": \"수정 제안\"
    }
  ],
  \"summary\": \"전체 요약\"
}
\`\`\`

critical/warning 이슈가 하나라도 있으면 verdict는 FAIL입니다.
"
```

Gemini의 응답을 `GEMINI_REVIEW` 변수에 저장합니다.

### Phase 4: Claude 평가

Claude Code가 Gemini의 검증 결과를 **비판적으로 평가**합니다:

Gemini가 지적한 각 이슈에 대해:

1. **타당성 판단**: 실제로 문제가 맞는지 코드를 직접 확인
2. **수용/거부 결정**:
   - ✅ **수용**: 실제 문제이면 수정 진행
   - ❌ **거부**: 오탐(false positive)이면 근거와 함께 기각
   - ⏭️ **보류**: suggestion 등급은 현재 스코프 밖이면 보류

평가 결과를 기록합니다:

```
🔄 Duo Loop - Round N 평가
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Gemini 판정: FAIL (score: 7/10)
이슈 총 5개: 🔴 critical 1 | 🟡 warning 2 | 🔵 suggestion 2

이슈별 Claude 평가:
  #1 [🔴 critical] SQL 인젝션 위험
     → ✅ 수용: 맞다, parameterized query로 수정 필요
  #2 [🟡 warning] 에러 핸들링 누락
     → ✅ 수용: try-catch 추가
  #3 [🟡 warning] 변수명 불명확
     → ❌ 거부: 프로젝트 컨벤션에 맞는 이름임
  #4 [🔵 suggestion] 함수 분리
     → ⏭️ 보류: 현재 스코프 밖
  #5 [🔵 suggestion] 타입 추가
     → ⏭️ 보류: 현재 스코프 밖

수용: 2개 → 수정 진행
거부: 1개 | 보류: 2개
```

### Phase 5: 수정 및 재검증

수용한 이슈를 Claude Code가 수정한 뒤, **Phase 3로 돌아가** Gemini에게 다시 검증받습니다.

### 종료 조건

다음 중 하나를 만족하면 루프 종료:
1. ✅ Gemini verdict가 `PASS` (score 8 이상)
2. ✅ 남은 이슈가 모두 `suggestion` 이하
3. ✅ Claude가 모든 이슈를 `거부`했고 근거가 타당함
4. ⚠️ 최대 라운드 초과 (기본: 5라운드) - 사용자에게 판단 요청

## 루프 상태 파일

루프 진행 상태를 `.claude/duo-loop-state.json`에 저장:

```json
{
  "task": "원래 작업 설명",
  "startedAt": "2026-02-07T10:00:00Z",
  "currentRound": 3,
  "maxRounds": 5,
  "rounds": [
    {
      "round": 1,
      "geminiVerdict": "FAIL",
      "geminiScore": 6,
      "totalIssues": 5,
      "accepted": 3,
      "rejected": 1,
      "deferred": 1,
      "fixesApplied": 3
    },
    {
      "round": 2,
      "geminiVerdict": "FAIL",
      "geminiScore": 8,
      "totalIssues": 2,
      "accepted": 1,
      "rejected": 1,
      "deferred": 0,
      "fixesApplied": 1
    },
    {
      "round": 3,
      "geminiVerdict": "PASS",
      "geminiScore": 9,
      "totalIssues": 1,
      "accepted": 0,
      "rejected": 0,
      "deferred": 1,
      "fixesApplied": 0
    }
  ],
  "status": "completed"
}
```

## 최종 보고서

루프 완료 시:

```
🏁 Duo Loop 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

작업:     $ARGUMENTS
라운드:   3회 (최대 5회)
최종 점수: 9/10 ✅ PASS

라운드별 점수: 6 → 8 → 9 📈

수정 이력:
  Round 1: SQL 인젝션 수정, 에러 핸들링 추가, null 체크 추가
  Round 2: 입력 검증 강화

거부한 이슈 (2개):
  - "변수명 불명확" → 프로젝트 컨벤션 준수
  - "불필요한 추상화" → 현재 구조가 더 명확

변경된 파일:
  src/api/users.ts
  src/middleware/auth.ts
  src/utils/validate.ts

💾 상태: .claude/duo-loop-state.json
💡 메모리로 저장하려면: /memory-save decision duo-loop 결과 요약
```

## 사용 예시

```
/duo-loop 사용자 인증 API를 JWT 기반으로 구현해줘
/duo-loop 기존 REST API를 GraphQL로 마이그레이션해줘
/duo-loop 결제 시스템에 Stripe 연동을 추가해줘
/duo-loop 이 프로젝트의 테스트 커버리지를 80% 이상으로 올려줘
```
