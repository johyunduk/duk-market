#!/usr/bin/env bash
# duk-market: @gemini keyword trigger
# Detects @gemini in user prompts and auto-calls Gemini CLI
# Triggered by UserPromptSubmit hook
# Output is injected into Claude's context as user feedback

set -e

# Read hook input from stdin (JSON)
INPUT=$(cat)

# Extract user prompt from JSON payload
USER_PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Handle various possible field names
    prompt = d.get('user_prompt', d.get('prompt', d.get('content', '')))
    print(prompt)
except:
    # If not JSON, treat raw input as prompt
    print(sys.stdin.read() if False else '')
" 2>/dev/null || echo "")

# Fallback: if JSON parsing failed, use raw input
if [ -z "$USER_PROMPT" ]; then
  USER_PROMPT="$INPUT"
fi

# Check if @gemini keyword exists (case-insensitive)
if ! echo "$USER_PROMPT" | grep -qi '@gemini'; then
  exit 0
fi

# Extract the question by removing @gemini keyword
QUESTION=$(echo "$USER_PROMPT" | sed 's/@[Gg][Ee][Mm][Ii][Nn][Ii]//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$QUESTION" ]; then
  echo "[duk-market] @gemini 키워드가 감지되었지만 질문이 비어 있습니다."
  echo "  사용법: @gemini 질문 내용을 입력하세요"
  exit 0
fi

# Check if gemini CLI is available
if ! command -v gemini &>/dev/null; then
  echo "[duk-market] Gemini CLI가 설치되어 있지 않습니다."
  echo "  설치: npm install -g @google/gemini-cli"
  echo "  인증: gemini auth login"
  exit 0
fi

# Call Gemini CLI
GEMINI_RESPONSE=$(gemini -p "$QUESTION" 2>&1) || {
  EXIT_CODE=$?
  echo ""
  echo "[duk-market] @gemini 자동 호출 실패 (exit code: $EXIT_CODE)"
  echo ""
  case "$GEMINI_RESPONSE" in
    *"auth"*|*"login"*|*"credential"*)
      echo "  원인: 인증 필요 → gemini auth login"
      ;;
    *"not found"*|*"command not found"*)
      echo "  원인: 설치 필요 → npm install -g @google/gemini-cli"
      ;;
    *)
      echo "  오류: $GEMINI_RESPONSE"
      echo "  네트워크 연결을 확인하세요."
      ;;
  esac
  exit 0
}

# Output Gemini's response (injected into Claude's context)
echo ""
echo "💎 [duk-market] @gemini 자동 응답"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$GEMINI_RESPONSE"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "위 내용은 Gemini의 응답입니다. Claude의 답변과 비교하여 참고하세요."

exit 0
