#!/usr/bin/env bash
# publish-s3.sh <dist-dir> <bucket> <distribution-id>
#
# Deploys a Vite/SPA build to S3 + CloudFront with cache-safe ordering.
#
# Usage:
#   ./scripts/ops/publish-s3.sh dist africair-app-bucket-dev EXXXXXXXXXXXX
#
# Requirements: aws CLI v2, configured profile with s3 + cloudfront permissions.

set -euo pipefail

DIST_DIR="${1:?Usage: $0 <dist-dir> <bucket> <distribution-id>}"
BUCKET="${2:?Usage: $0 <dist-dir> <bucket> <distribution-id>}"
DIST_ID="${3:?Usage: $0 <dist-dir> <bucket> <distribution-id>}"

if [[ ! -d "$DIST_DIR" ]]; then
  echo "ERROR: dist-dir '$DIST_DIR' not found." >&2
  exit 1
fi

echo "==> [1/4] Uploading hashed assets (cache-forever)..."
# Upload assets/ FIRST.
# These files have content-addressed names (e.g. main.a1b2c3d4.js).
# They are safe to cache forever because the name changes on every build.
# Uploading them before index.html means the new assets are already on S3
# (and CloudFront edge) before any client is told to request them.
aws s3 sync \
  "${DIST_DIR}/assets/" \
  "s3://${BUCKET}/assets/" \
  --cache-control "public,max-age=31536000,immutable" \
  --metadata-directive REPLACE

echo "==> [2/4] Uploading index.html (no-cache)..."
# Upload index.html AFTER assets are live.
# index.html references the new asset filenames. If it went live first,
# browsers that fetched the old index.html would be directed to assets
# that don't exist yet, causing a blank/broken app.
aws s3 cp \
  "${DIST_DIR}/index.html" \
  "s3://${BUCKET}/index.html" \
  --cache-control "no-cache" \
  --metadata-directive REPLACE \
  --content-type "text/html"

echo "==> [3/4] Uploading version.json (no-cache)..."
if [[ -f "${DIST_DIR}/version.json" ]]; then
  aws s3 cp \
    "${DIST_DIR}/version.json" \
    "s3://${BUCKET}/version.json" \
    --cache-control "no-cache" \
    --metadata-directive REPLACE \
    --content-type "application/json"
fi

echo "==> [4/4] Removing stale files..."
# --delete runs LAST, after the new index.html is live.
# Deleting old assets before index.html is updated would break users
# whose browsers cached the old index.html — it would reference files
# that are now gone. Deleting after means any in-flight request for the
# old index.html can still load the old assets (they are still present),
# while new visitors get the new index.html pointing to new assets.
aws s3 sync \
  "${DIST_DIR}/" \
  "s3://${BUCKET}/" \
  --delete \
  --exact-timestamps

echo "==> [5/5] Invalidating /index.html and /version.json..."
# We invalidate only the two no-cache entry points, never /*, because:
#
# 1. Hashed assets (/assets/main.a1b2c3d4.js) never change name, so their
#    cached copies are correct by definition — invalidating them wastes money
#    ($0.005 per 1,000 paths after the free 1,000/month) and adds latency.
#
# 2. A /* wildcard counts as ONE path against the free tier but evicts the
#    ENTIRE edge cache. Every user worldwide takes a cold-cache miss on the
#    next request, spiking origin load and increasing TTFB globally.
#
# 3. index.html and version.json have no-cache headers, so browsers
#    revalidate them on every load anyway — but CloudFront still serves a
#    stale copy from its own TTL until invalidated. These two paths are
#    the only ones where a forced eviction is needed.
aws cloudfront create-invalidation \
  --distribution-id "${DIST_ID}" \
  --paths "/index.html" "/version.json"

echo "==> Done. Deployment complete."
