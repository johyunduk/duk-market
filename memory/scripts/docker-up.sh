#!/usr/bin/env bash
# Ensure duk-memory Docker container is running

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v docker &>/dev/null; then
  echo "[duk-memory] Error: Docker is not installed." >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^duk-memory$'; then
  docker compose -f "$PLUGIN_DIR/docker-compose.yml" up -d --quiet-pull 2>/dev/null
  sleep 1
fi
