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

# Notify user that Gemini is being called (visible in terminal via /dev/tty)
printf '\n💎 \033[36m[Gemini]\033[0m 호출 중...\n' > /dev/tty 2>/dev/null || true

# Call Gemini CLI
# NODE_NO_WARNINGS suppresses node deprecation warnings
# grep filters remaining gemini CLI informational noise
GEMINI_RAW=$(NODE_NO_WARNINGS=1 gemini -p "$QUESTION" 2>/dev/null)
EXIT_CODE=$?

GEMINI_RESPONSE=$(printf '%s\n' "$GEMINI_RAW" | python3 -c "
import sys
noise = [
  'DeprecationWarning', 'punycode', 'node --trace', '(node:',
  'Loaded cached credentials', 'Hook registry initialized',
  'supports tool updates', 'Listening for changes',
  'Retrying with backoff', 'GaxiosError', 'at async ',
  'rateLimitExceeded', 'MODEL_CAPACITY', 'Attempt ', 'DEP0040',
]
for line in sys.stdin:
    if not any(n in line for n in noise):
        sys.stdout.write(line)
" 2>/dev/null || printf '%s\n' "$GEMINI_RAW")

if [ $EXIT_CODE -ne 0 ] || [ -z "$(echo "$GEMINI_RESPONSE" | tr -d '[:space:]')" ]; then
  printf '💎 \033[31m[Gemini]\033[0m 호출 실패\n' > /dev/tty 2>/dev/null || true
  echo ""
  echo "[duk-market] @gemini 자동 호출 실패"
  ERRMSG=$(NODE_NO_WARNINGS=1 gemini -p "$QUESTION" 2>&1 || true)
  case "$ERRMSG" in
    *"auth"*|*"login"*|*"credential"*)
      echo "  원인: 인증 필요 → gemini auth login" ;;
    *"not found"*|*"command not found"*)
      echo "  원인: 설치 필요 → npm install -g @google/gemini-cli" ;;
    *)
      echo "  네트워크 연결을 확인하세요." ;;
  esac
  exit 0
fi

# Notify user that Gemini responded (visible in terminal via /dev/tty)
printf '💎 \033[36m[Gemini]\033[0m 응답 완료 — Claude가 참고합니다\n' > /dev/tty 2>/dev/null || true

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
