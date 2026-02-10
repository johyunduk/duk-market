---
name: gemini-research
description: Gemini의 웹 검색과 대규모 컨텍스트 능력을 활용하여 기술 리서치를 수행하고, 결과를 Claude Code에 전달합니다
user-invocable: true
allowed-tools: Bash, Read, Write, Grep, Glob
argument-hint: "<리서치 주제>"
---

# Gemini Research - Gemini가 조사, Claude가 적용

Gemini의 Google 검색 통합과 1M 토큰 컨텍스트를 활용하여 기술 리서치를 수행하고,
그 결과를 Claude Code가 프로젝트에 적용합니다.

## 활용 시나리오

- 최신 라이브러리/프레임워크 사용법 조사
- 에러 메시지 해결책 검색
- 아키텍처 패턴/베스트 프랙티스 리서치
- 경쟁 기술 비교 분석

## 워크플로우

### 1단계: 리서치 요청 구성

```bash
gemini -p "
당신은 기술 리서치 전문가입니다.
다음 주제에 대해 심층 조사를 수행해주세요.

## 리서치 주제
$ARGUMENTS

## 현재 프로젝트 기술 스택
$(cat package.json 2>/dev/null || cat requirements.txt 2>/dev/null || cat go.mod 2>/dev/null || echo '정보 없음')

## 응답 형식

### 핵심 요약
(3-5줄 요약)

### 조사 결과
(상세한 기술 분석)

### 추천 솔루션
(프로젝트에 적용 가능한 구체적 방안, 우선순위 순)

### 코드 예제
(바로 사용할 수 있는 코드 스니펫)

### 참고 자료
(공식 문서, GitHub 레포 등 링크)

### 주의사항
(호환성 이슈, 알려진 버그, deprecated 기능 등)
"
```

### 2단계: 결과 정리 및 표시

Gemini의 리서치 결과를 사용자에게 보여줍니다.

### 3단계: 적용 여부 확인

> Gemini 리서치가 완료되었습니다. 추천 솔루션을 프로젝트에 적용할까요?

사용자가 승인하면 Claude Code가:
1. 필요한 패키지 설치
2. 코드 예제를 프로젝트에 맞게 수정하여 적용
3. 기존 코드와의 통합

### 4단계: 결과 보고

```
🔍 Gemini 리서치 → Claude 적용 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 리서치 주제: $ARGUMENTS

📊 Gemini 조사 결과:
   (핵심 요약)

🔧 Claude 적용:
   - 설치: package-name@version
   - 생성: config.ts
   - 수정: app.ts

📎 참고 자료:
   - https://...
```

## 사용 예시

```
/gemini-research Next.js 15 서버 컴포넌트에서 스트리밍 SSR 구현 방법
/gemini-research PostgreSQL에서 대용량 테이블 파티셔닝 전략
/gemini-research "ECONNREFUSED" 에러가 Docker compose 환경에서 발생하는 원인과 해결책
/gemini-research Rust와 Go의 웹소켓 성능 비교
```
