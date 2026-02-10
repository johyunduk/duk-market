#!/usr/bin/env bash
# duk-memory 최초 1회 설정: Docker 이미지 빌드 + 컨테이너 기동 + DB 초기화

set -e

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$PLUGIN_DIR/docker-compose.yml"
INIT_FLAG="$HOME/.claude/duk-market-data/.initialized"

if ! command -v docker &>/dev/null; then
  echo "[duk-memory] Error: Docker is not installed." >&2
  exit 1
fi

echo "[duk-memory] Docker 이미지 빌드 중..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo "[duk-memory] DB 초기화 중..."
"$PLUGIN_DIR/scripts/init-db.sh"

echo "[duk-memory] 설정 완료."
