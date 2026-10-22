#!/usr/bin/env bash
# scripts/ops/test-deployer-permissions.sh
#
# Proves the deployer policy is least-privilege.
#
# Prerequisites:
#   1. Run `terraform apply` to create the deployer IAM user.
#   2. Create an access key for the user:
#        aws iam create-access-key \
#          --user-name <cluster_name>-<env>-deployer \
#          --profile terraform
#   3. Add those keys to your AWS config as profile [deployer-test]:
#        aws configure --profile deployer-test
#   4. Set the env vars below, or pass them as arguments.
#
# Usage:
#   BUCKET=landmark-app-bucket-dev \
#   DIST_ID=EXXXXXXXXXXXX \
#   ./scripts/ops/test-deployer-permissions.sh

set -euo pipefail

BUCKET="${1:-${BUCKET:?Set BUCKET or pass as \$1}}"
DIST_ID="${2:-${DIST_ID:?Set DIST_ID or pass as \$2}}"
PROFILE="${AWS_PROFILE:-deployer-test}"

echo "========================================"
echo " Deployer least-privilege proof"
echo " Profile : $PROFILE"
echo " Bucket  : $BUCKET"
echo " Dist ID : $DIST_ID"
echo "========================================"

# ── ALLOWED: ListBucket on the correct bucket ─────────────────────────────────
echo ""
echo "[PASS expected] s3:ListBucket on s3://$BUCKET ..."
aws s3 ls "s3://${BUCKET}" --profile "$PROFILE" && \
  echo "  ✅  ListBucket allowed (expected)" || \
  echo "  ❌  UNEXPECTED DENY — check policy"

# ── ALLOWED: PutObject (upload a probe file) ──────────────────────────────────
echo ""
echo "[PASS expected] s3:PutObject on s3://$BUCKET/deployer-probe.txt ..."
echo "probe" | aws s3 cp - "s3://${BUCKET}/deployer-probe.txt" \
  --profile "$PROFILE" && \
  echo "  ✅  PutObject allowed (expected)" || \
  echo "  ❌  UNEXPECTED DENY — check policy"

# ── ALLOWED: DeleteObject (clean up the probe file) ───────────────────────────
echo ""
echo "[PASS expected] s3:DeleteObject on s3://$BUCKET/deployer-probe.txt ..."
aws s3 rm "s3://${BUCKET}/deployer-probe.txt" \
  --profile "$PROFILE" && \
  echo "  ✅  DeleteObject allowed (expected)" || \
  echo "  ❌  UNEXPECTED DENY — check policy"

# ── DENIED: ListBucket on a DIFFERENT bucket ─────────────────────────────────
echo ""
echo "[DENY expected] s3:ListBucket on a bucket this user does NOT own ..."
DENY_OUTPUT=$(aws s3 ls s3://some-other-bucket-not-ours \
  --profile "$PROFILE" 2>&1 || true)

if echo "$DENY_OUTPUT" | grep -q "AccessDenied\|Access Denied"; then
  echo "  ✅  AccessDenied received (expected)"
  echo "      $DENY_OUTPUT"
else
  echo "  ❌  NO DENY — policy may be too broad"
  echo "      $DENY_OUTPUT"
fi

# ── DENIED: GetObject (deployer must not READ objects) ────────────────────────
echo ""
echo "[DENY expected] s3:GetObject on s3://$BUCKET/index.html ..."
DENY_OUTPUT=$(aws s3 cp "s3://${BUCKET}/index.html" - \
  --profile "$PROFILE" 2>&1 || true)

if echo "$DENY_OUTPUT" | grep -q "AccessDenied\|Access Denied"; then
  echo "  ✅  AccessDenied received (expected)"
else
  echo "  ❌  NO DENY — deployer should not read objects"
  echo "      $DENY_OUTPUT"
fi

# ── DENIED: CreateInvalidation on a DIFFERENT distribution ───────────────────
echo ""
echo "[DENY expected] cloudfront:CreateInvalidation on a different distribution ..."
DENY_OUTPUT=$(aws cloudfront create-invalidation \
  --distribution-id ENOTTHISONE111 \
  --paths "/index.html" \
  --profile "$PROFILE" 2>&1 || true)

if echo "$DENY_OUTPUT" | grep -q "AccessDenied\|Access Denied\|NoSuchDistribution"; then
  echo "  ✅  AccessDenied/NoSuchDistribution received (expected)"
  echo "      $DENY_OUTPUT"
else
  echo "  ❌  NO DENY — policy may be too broad"
  echo "      $DENY_OUTPUT"
fi

echo ""
echo "========================================"
echo " Proof complete."
echo "========================================"
