#!/usr/bin/env bash
# Checks /healthz and /api/healthz. Logs to systemd journal (stdout/stderr).
# Exit 0 = healthy. Exit 1 = unhealthy (systemd marks the run as failed).
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
TIMEOUT=5

fail() { echo "UNHEALTHY: $1" >&2; exit 1; }

# nginx /healthz (inline return 200)
curl -sf --max-time "$TIMEOUT" "${BASE_URL}/healthz" > /dev/null \
  || fail "/healthz did not return 200"

# Node API /api/healthz
curl -sf --max-time "$TIMEOUT" "${BASE_URL}/api/healthz" > /dev/null \
  || fail "/api/healthz did not return 200"

# version.json must be present and contain a commit field
COMMIT=$(curl -sf --max-time "$TIMEOUT" "${BASE_URL}/version.json" \
  | jq -r '.commit // empty')
[[ -n "$COMMIT" ]] || fail "/version.json missing or has no commit field"

echo "OK  commit=${COMMIT}"
