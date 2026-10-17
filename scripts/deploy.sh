#!/usr/bin/env bash
set -uo pipefail

# Exit codes:
#   10  git checkout failure
#   20  pnpm install failure
#   30  test failure
#   40  build failure

usage() {
  cat <<EOF
Usage: $0 <git-ref>

Build and package AfricAir from a git ref (branch, tag or SHA).

Exit codes:
  10  git clone / checkout failed
  20  pnpm install --frozen-lockfile failed
  30  pnpm test failed
  40  pnpm build or packaging failed

Examples:
  $0 main
  $0 v1.0.0
  $0 abc1234
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage; exit 0
fi

GIT_REF="${1:?$(usage)}"
REPO_URL="https://github.com/ninamonopoly/africair"

# Clone and checkout
BUILD_DIR=$(mktemp -d /tmp/africair-build-XXXXXX)
git clone "$REPO_URL" "$BUILD_DIR" && cd "$BUILD_DIR" && git checkout "$GIT_REF" || exit 10

# Install
pnpm install --frozen-lockfile || exit 20

# Test
pnpm test || exit 30

# Build + version.json + package
{
  pnpm build
  pnpm build:api

  SHORT_SHA=$(git rev-parse --short HEAD)

  jq -n \
    --arg commit "$(git rev-parse HEAD)" \
    --arg ref "$GIT_REF" \
    --arg builtAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg builtBy "$(whoami)@$(hostname)" \
    --arg nodeVersion "$(node -v)" \
    '{commit: $commit, ref: $ref, builtAt: $builtAt, builtBy: $builtBy, nodeVersion: $nodeVersion}' \
    > dist/version.json

  # --- Frontend artifact ---
  tar czf "africair-${SHORT_SHA}.tar.gz" dist/
  sha256sum "africair-${SHORT_SHA}.tar.gz" > "africair-${SHORT_SHA}.tar.gz.sha256"

  # --- API artifact: server/dist + server/migrations + production node_modules ---
  # Install prod-only deps into a staging dir so we don't ship devDependencies
  API_STAGE=$(mktemp -d /tmp/africair-api-stage-XXXXXX)
  cp -r server/dist server/migrations "$API_STAGE/"
  cp package.json pnpm-lock.yaml "$API_STAGE/"
  (cd "$API_STAGE" && pnpm install --frozen-lockfile --prod)
  rm "$API_STAGE/package.json" "$API_STAGE/pnpm-lock.yaml"

  tar czf "africair-api-${SHORT_SHA}.tar.gz" -C "$API_STAGE" .
  sha256sum "africair-api-${SHORT_SHA}.tar.gz" > "africair-api-${SHORT_SHA}.tar.gz.sha256"
  rm -rf "$API_STAGE"

  echo "Build complete: $BUILD_DIR"
  cat dist/version.json
  ls -lh "africair-${SHORT_SHA}.tar.gz" "africair-api-${SHORT_SHA}.tar.gz"
} || exit 40
