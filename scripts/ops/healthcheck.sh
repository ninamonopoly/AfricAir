#!/usr/bin/env bash
# Logs to journald via: logger -t africair-health
# Tracks consecutive failures in /var/lib/africair/healthcheck.failures
# After 3 consecutive failures: reloads nginx and logs a WARNING.
# Exit 0 = healthy. Exit 1 = unhealthy.
set -uo pipefail

BASE_URL="${BASE_URL:-http://localhost}"
TIMEOUT=5
TAG=africair-health
STATE_DIR=/var/lib/africair
STATE_FILE="${STATE_DIR}/healthcheck.failures"
FAIL_THRESHOLD=3

log()  { logger -t "$TAG" -- "$*"; }
warn() { logger -t "$TAG" -p user.warning -- "WARNING: $*"; }
err()  { logger -t "$TAG" -p user.err -- "UNHEALTHY: $*"; }

mkdir -p "$STATE_DIR"

check_failed() {
  local reason="$1"
  err "$reason"
  local count=0
  [[ -f "$STATE_FILE" ]] && count=$(<"$STATE_FILE")
  count=$(( count + 1 ))
  echo "$count" > "$STATE_FILE"
  if (( count >= FAIL_THRESHOLD )); then
    warn "${count} consecutive failures — reloading nginx"
    systemctl reload nginx
  fi
  exit 1
}

curl -sf --max-time "$TIMEOUT" "${BASE_URL}/healthz" > /dev/null \
  || check_failed "/healthz did not return 200"

curl -sf --max-time "$TIMEOUT" "${BASE_URL}/api/healthz" > /dev/null \
  || check_failed "/api/healthz did not return 200"

COMMIT=$(curl -sf --max-time "$TIMEOUT" "${BASE_URL}/version.json" \
  | jq -r '.commit // empty')
[[ -n "$COMMIT" ]] || check_failed "/version.json missing or has no commit field"

# All checks passed — reset failure counter
echo 0 > "$STATE_FILE"
log "OK commit=${COMMIT}"
