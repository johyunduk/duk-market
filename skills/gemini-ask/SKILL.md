---
name: gemini-ask
description: Gemini에게 직접 질문하고 응답을 받습니다. 간단한 질문이나 second opinion이 필요할 때 사용합니다
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<질문>"
---

# Gemini Ask - Gemini에게 직접 질문

Gemini CLI를 통해 직접 질문하고 응답을 받습니다.
Claude와 다른 시각의 의견(second opinion)이 필요하거나, Gemini의 Google 검색 능력을 활용하고 싶을 때 사용합니다.

## 워크플로우

### 1단계: Gemini 호출

```bash
gemini -p "$ARGUMENTS"
```

컨텍스트가 필요한 질문이면 관련 파일을 파이프로 전달:

```bash
cat relevant_file.ts | gemini -p "이 코드에 대해: $ARGUMENTS"
```

### 2단계: 응답 표시

Gemini의 응답을 그대로 사용자에게 전달합니다:

```
💎 Gemini 응답
━━━━━━━━━━━━━━━━━━━━━━━━

(Gemini의 응답 내용)

━━━━━━━━━━━━━━━━━━━━━━━━
💡 이 내용을 바탕으로 구현이 필요하면 /gemini-analyze를 사용하세요.
```

### 3단계: 후속 조치

사용자가 Gemini 응답을 바탕으로 추가 작업을 요청하면 Claude Code가 수행합니다.

## Gemini CLI 오류 처리

`gemini` 명령이 실패할 경우:

```
⚠️ Gemini CLI 오류

가능한 원인:
1. 설치 안 됨 → npm install -g @google/gemini-cli
2. 인증 필요 → gemini auth login
3. API 키 미설정 → export GEMINI_API_KEY="your-key"
4. 네트워크 오류 → 인터넷 연결 확인

자세한 설정: https://github.com/google-gemini/gemini-cli
```

## 사용 예시

```
/gemini-ask TypeScript 5.7의 새로운 기능은?
/gemini-ask React Server Components와 Next.js App Router의 차이점
/gemini-ask 이 에러 해결법: "Cannot read property of undefined"
```
