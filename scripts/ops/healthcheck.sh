#!/usr/bin/env bash
# Logs to journald via: logger -t africair-health
# Exit 0 = healthy. Exit 1 = unhealthy (systemd marks the run as failed).
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
TIMEOUT=5
TAG=africair-health

log()  { logger -t "$TAG" -- "$*"; }
fail() { logger -t "$TAG" -p user.err -- "UNHEALTHY: $*"; exit 1; }

curl -sf --max-time "$TIMEOUT" "${BASE_URL}/healthz" > /dev/null \
  || fail "/healthz did not return 200"

curl -sf --max-time "$TIMEOUT" "${BASE_URL}/api/healthz" > /dev/null \
  || fail "/api/healthz did not return 200"

COMMIT=$(curl -sf --max-time "$TIMEOUT" "${BASE_URL}/version.json" \
  | jq -r '.commit // empty')
[[ -n "$COMMIT" ]] || fail "/version.json missing or has no commit field"

log "OK commit=${COMMIT}"
