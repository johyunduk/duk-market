#!/usr/bin/env bash
# Ensure duk-memory Docker container is running

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$PLUGIN_DIR/docker-compose.yml"

if ! command -v docker &>/dev/null; then
  echo "[duk-memory] Error: Docker is not installed." >&2
  exit 1
fi

# Already running
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^duk-memory$'; then
  exit 0
fi

# Container exists but stopped → just start it
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^duk-memory$'; then
  docker start duk-memory >/dev/null 2>&1
  sleep 1
  exit 0
fi

# First time: build and start
echo "[duk-memory] 컨테이너 초기 빌드 중..." >&2
docker compose -f "$COMPOSE_FILE" up -d --build
echo "[duk-memory] 컨테이너 기동 완료" >&2

# Auto-initialize DB schema on first run
"$(dirname "$0")/init-db.sh"
