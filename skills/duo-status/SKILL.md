---
name: duo-status
description: 현재 진행 중이거나 완료된 Duo Loop의 상태를 확인합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "[--history]"
---

# Duo Status - 루프 상태 확인

현재 진행 중이거나 최근 완료된 Duo Loop의 상태를 보여줍니다.

## 동작

### 상태 파일 읽기

`.claude/duo-loop-state.json`을 읽어서 현재 루프 상태를 표시합니다.

### 기본 출력 (진행 중)

```
🔄 Duo Loop 진행 중
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

작업:     사용자 인증 API JWT 구현
시작:     2026-02-07 10:00
현재:     Round 2/5
소요:     12분

라운드 기록:
  Round 1: FAIL (6/10) → 수용 3, 거부 1, 보류 1
  Round 2: 진행 중... (Gemini 검증 대기)

점수 추이: 6 → ?
```

### 기본 출력 (완료)

```
✅ Duo Loop 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

작업:     사용자 인증 API JWT 구현
완료:     2026-02-07 10:25 (25분 소요)
라운드:   3/5
최종 점수: 9/10 PASS

점수 추이: 6 → 8 → 9 📈

총 이슈: 8개 발견 → 5개 수정, 2개 거부, 1개 보류
```

### 히스토리 (`--history`)

과거 Duo Loop 기록 목록을 표시합니다.
`.claude/duo-loop-state.json`의 히스토리 섹션 또는 이전 state 파일들을 검색.

```
📋 Duo Loop 히스토리
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. [02-07 10:00] JWT 인증 구현 - 3R, 9/10 ✅
2. [02-06 15:30] GraphQL 마이그레이션 - 4R, 8/10 ✅
3. [02-06 09:00] Stripe 결제 연동 - 5R, 7/10 ⚠️ (최대 라운드 도달)
```

## 사용 예시

```
/duo-status            # 현재/최근 루프 상태
/duo-status --history  # 전체 히스토리
```
