#!/usr/bin/env bash
set -uo pipefail

# Exit codes:
#   10  artifact not found or checksum verification failed
#   20  failed to extract artifact
#   30  failed to create release directory
#   40  failed to update current symlink
#   50  nginx config invalid
#   60  smoke test failed (rolled back)

usage() {
  cat <<EOF
Usage: $0 <artifact.tar.gz>

Deploy a pre-built AfricAir artifact to /opt/africair.

Arguments:
  <artifact.tar.gz>   Path to the build tarball (e.g. africair-abc1234.tar.gz)

Exit codes:
  10  artifact not found or checksum verification failed
  20  failed to extract artifact
  30  failed to create release directory
  40  failed to update current symlink
  50  nginx config invalid
  60  smoke test failed (rolled back)

Examples:
  $0 africair-abc1234.tar.gz
  $0 /tmp/africair-build-XXXXXX/africair-abc1234.tar.gz

Repository: https://github.com/ninamonopoly/africair
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage; exit 0
fi

ARTIFACT="${1:?$(usage)}"
DEPLOY_DIR="/opt/africair"
RELEASES_DIR="$DEPLOY_DIR/releases"
APP_PORT="${APP_PORT:-80}"
APP_HOST="${APP_HOST:-localhost}"
BASE_URL="http://${APP_HOST}:${APP_PORT}"

# Verify artifact and checksum file both exist
[[ -f "$ARTIFACT" ]] || { echo "ERROR: artifact not found: $ARTIFACT"; exit 10; }
[[ -f "${ARTIFACT}.sha256" ]] || { echo "ERROR: checksum file not found: ${ARTIFACT}.sha256"; exit 10; }

# Abort if checksum does not match
sha256sum --check "${ARTIFACT}.sha256" || { echo "ERROR: checksum verification failed"; exit 10; }

# Extract SHA from filename (africair-<shortsha>.tar.gz)
SHA=$(basename "$ARTIFACT" .tar.gz | sed 's/africair-//')
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
RELEASE_DIR="$RELEASES_DIR/${TIMESTAMP}-${SHA}"

# Create release directory and extract
sudo mkdir -p "$RELEASE_DIR" || exit 30
sudo tar xzf "$ARTIFACT" -C "$RELEASE_DIR" --strip-components=1 || exit 20

# Set ownership
sudo chown -R africair:africair "$RELEASE_DIR"

# Capture previous release for rollback
PREV_RELEASE=$(readlink -f "$DEPLOY_DIR/current" 2>/dev/null || true)

rollback() {
  echo "ERROR: $1 — rolling back to ${PREV_RELEASE:-none}"
  if [[ -n "$PREV_RELEASE" ]]; then
    sudo ln -sfn "$PREV_RELEASE" "$DEPLOY_DIR/current.new"
    sudo mv -T "$DEPLOY_DIR/current.new" "$DEPLOY_DIR/current"
    sudo nginx -t && sudo systemctl reload nginx
    echo "Rolled back to $PREV_RELEASE"
  fi
  exit 60
}

# Update current symlink atomically using ln + mv -T
# ln -sfn alone is not atomic: it unlinks then relinks, leaving a window
# where current does not exist. mv -T replaces the symlink in one syscall.
sudo ln -sfn "$RELEASE_DIR" "$DEPLOY_DIR/current.new" || exit 40
sudo mv -T "$DEPLOY_DIR/current.new" "$DEPLOY_DIR/current" || exit 40

# Validate nginx config before reloading — never restart (restart drops connections)
sudo nginx -t || { echo "ERROR: nginx config invalid, skipping reload"; exit 50; }
sudo systemctl reload nginx

# Smoke tests: /healthz must return 200; /version.json commit must match artifact SHA
sleep 2

curl -sf "${BASE_URL}/healthz" > /dev/null \
  || rollback "/healthz did not return 200"

DEPLOYED_COMMIT=$(curl -sf "${BASE_URL}/version.json" | jq -r '.commit // empty')
[[ "$DEPLOYED_COMMIT" == "$SHA"* || "$SHA" == "${DEPLOYED_COMMIT:0:${#SHA}}" ]] \
  || rollback "/version.json commit mismatch: got '${DEPLOYED_COMMIT}', expected '${SHA}'"

echo "Deployed to $RELEASE_DIR"
echo "current -> $RELEASE_DIR"
echo "commit:  $DEPLOYED_COMMIT"
