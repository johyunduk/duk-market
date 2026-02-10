---
name: gemini-analyze
description: 코드베이스 분석을 Gemini에게 위임하고, 분석 결과를 바탕으로 Claude Code가 구현합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob, Write, Edit
argument-hint: "<분석할 내용 또는 구현 요청>"
---

# Gemini Analyze - 분석은 Gemini, 구현은 Claude

사용자의 요청을 받아 **분석/설계는 Gemini CLI**에 위임하고, 그 결과를 바탕으로 **코드 구현은 Claude Code**가 수행합니다.

## 워크플로우

### 1단계: 컨텍스트 수집

먼저 현재 프로젝트의 컨텍스트를 수집합니다:

```bash
# 프로젝트 구조 파악
PROJECT_TREE=$(find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.next/*' | head -100)

# 관련 파일 내용 (사용자 요청에 따라 선택)
```

### 2단계: Gemini에게 분석 요청

수집한 컨텍스트와 사용자 요청을 Gemini CLI에 전달합니다:

```bash
gemini -p "
당신은 시니어 소프트웨어 아키텍트입니다.
다음 프로젝트 컨텍스트와 요청을 분석하고, 구체적인 구현 계획을 제시해주세요.

## 프로젝트 구조
$PROJECT_TREE

## 관련 코드
(여기에 관련 파일 내용 포함)

## 요청
$ARGUMENTS

## 응답 형식
다음 형식으로 응답해주세요:

### 분석 요약
(문제/요청에 대한 분석)

### 구현 계획
1. 파일별 변경 사항
2. 새로 생성할 파일
3. 수정할 파일과 구체적인 변경 내용

### 핵심 로직
(pseudocode 또는 핵심 알고리즘)

### 주의사항
(엣지 케이스, 보안 고려사항 등)
"
```

**중요**: `gemini -p` 명령이 실패하면(설치 안 됨, 인증 안 됨 등) 사용자에게 안내:
```
Gemini CLI가 설치되어 있지 않거나 인증이 필요합니다.

설치: npm install -g @google/gemini-cli
인증: gemini auth login
또는: export GEMINI_API_KEY="your-key"
```

### 3단계: Gemini 분석 결과 정리

Gemini의 응답을 파싱하여 구조화합니다:
- **분석 요약**: 사용자에게 보여줌
- **구현 계획**: Claude Code가 실행할 작업 목록
- **핵심 로직**: 구현 시 참고할 코드/알고리즘

### 4단계: Claude Code가 구현

Gemini의 분석 결과를 바탕으로 실제 코드를 작성합니다:
1. Gemini가 제안한 파일별 변경 사항을 순서대로 구현
2. 핵심 로직을 실제 코드로 변환
3. 주의사항을 반영하여 안전한 코드 작성

### 5단계: 결과 보고

```
🤖 Gemini 분석 → Claude 구현 완료
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Gemini 분석:
   (분석 요약)

🔧 Claude 구현:
   - 생성: file1.ts, file2.ts
   - 수정: file3.ts
   - 삭제: 없음

✅ 완료된 작업:
   1. ...
   2. ...
```

## 사용 예시

```
/gemini-analyze 이 프로젝트에 사용자 인증 기능을 추가해줘
/gemini-analyze 현재 API의 성능 병목을 찾고 최적화해줘
/gemini-analyze 이 코드를 마이크로서비스 아키텍처로 리팩토링할 계획을 세워줘
```
