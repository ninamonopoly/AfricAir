#!/usr/bin/env bash
set -uo pipefail

# Exit codes:
#   10  git checkout failure
#   20  pnpm install failure
#   30  test failure
#   40  build failure

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

# Update current symlink atomically
sudo ln -sfn "$RELEASE_DIR" "$DEPLOY_DIR/current" || exit 40

echo "Deployed to $RELEASE_DIR"
echo "current -> $RELEASE_DIR"
