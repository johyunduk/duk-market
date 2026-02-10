#!/usr/bin/env bash
# 컨테이너가 실행 중인지 확인하고 필요하면 재기동 (빌드 없음)
# 최초 설정은 setup.sh 를 사용하세요.

if ! command -v docker &>/dev/null; then
  exit 1
fi

# 이미 실행 중
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^duk-memory$'; then
  exit 0
fi

# 컨테이너가 존재하지만 중지 상태 → 재기동
if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^duk-memory$'; then
  docker start duk-memory >/dev/null 2>&1
  sleep 1
  exit 0
fi

# 컨테이너 자체가 없으면 (setup.sh 미실행) → 조용히 종료
exit 1
