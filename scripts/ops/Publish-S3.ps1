# scripts/ops/Publish-S3.ps1
# PowerShell equivalent of publish-s3.sh
# Usage: .\scripts\ops\Publish-S3.ps1 -DistDir dist -Bucket africair-app-bucket-dev -DistributionId ERTERJ4EGO84I

param(
    [Parameter(Mandatory)][string]$DistDir,
    [Parameter(Mandatory)][string]$Bucket,
    [Parameter(Mandatory)][string]$DistributionId,
    [string]$Profile = "terraform"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $DistDir)) {
    Write-Error "dist-dir '$DistDir' not found. Run pnpm build first."
    exit 1
}

Write-Host "==> [1/4] Uploading hashed assets (cache-forever)..."
aws s3 sync "$DistDir/assets/" "s3://$Bucket/assets/" `
    --cache-control "public,max-age=31536000,immutable" `
    --metadata-directive REPLACE `
    --profile $Profile

Write-Host "==> [2/4] Uploading index.html (no-cache)..."
aws s3 cp "$DistDir/index.html" "s3://$Bucket/index.html" `
    --cache-control "no-cache" `
    --metadata-directive REPLACE `
    --content-type "text/html" `
    --profile $Profile

Write-Host "==> [3/4] Uploading version.json (no-cache)..."
if (Test-Path "$DistDir/version.json") {
    aws s3 cp "$DistDir/version.json" "s3://$Bucket/version.json" `
        --cache-control "no-cache" `
        --metadata-directive REPLACE `
        --content-type "application/json" `
        --profile $Profile
}

Write-Host "==> [4/4] Removing stale files..."
aws s3 sync "$DistDir/" "s3://$Bucket/" `
    --delete `
    --exact-timestamps `
    --profile $Profile

Write-Host "==> [5/5] Invalidating /index.html and /version.json..."
aws cloudfront create-invalidation `
    --distribution-id $DistributionId `
    --paths "/index.html" "/version.json" `
    --profile $Profile

Write-Host "==> Done. Deployment complete."
