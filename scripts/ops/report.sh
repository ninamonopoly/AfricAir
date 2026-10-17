#!/usr/bin/env bash
# Usage: report.sh [logfile]
# Default logfile: /var/log/nginx/africair.access.json
set -euo pipefail

LOG="${1:-/var/log/nginx/africair.access.json}"
[[ -f "$LOG" ]] || { echo "log not found: $LOG" >&2; exit 1; }

echo "=== Top 10 client IPs ==="
jq -r '.remote_addr' "$LOG" \
  | sort | uniq -c | sort -rn | head -10 \
  | awk '{printf "%6s  %s\n", $1, $2}'

echo ""
echo "=== Requests by status class ==="
jq -r '.status' "$LOG" \
  | awk '{print int($1/100)"xx"}' \
  | sort | uniq -c | sort -rn \
  | awk '{printf "%6s  %s\n", $1, $2}'

echo ""
echo "=== Top 10 most requested paths ==="
jq -r '.uri' "$LOG" \
  | awk -F'?' '{print $1}' \
  | sort | uniq -c | sort -rn | head -10 \
  | awk '{printf "%6s  %s\n", $1, $2}'

echo ""
echo "=== Requests per minute (last 60 minutes) ==="
SINCE=$(date -u -d "60 minutes ago" +%Y-%m-%dT%H:%M 2>/dev/null \
     || date -u -v-60M +%Y-%m-%dT%H:%M)  # macOS fallback
jq -r '.time' "$LOG" \
  | awk -F: -v since="$SINCE" '$0 >= since {print $1":"$2}' \
  | sort | uniq -c \
  | awk '{printf "%6s  %s\n", $1, $2}'
