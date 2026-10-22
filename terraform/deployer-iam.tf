# ── Least-privilege deployer IAM policy ──────────────────────────────────────
#
# Grants exactly what publish-s3.sh needs and nothing else:
#   - s3:ListBucket      on the bucket (needed for --delete to diff the set)
#   - s3:PutObject       on bucket/*   (sync + cp)
#   - s3:DeleteObject    on bucket/*   (--delete removes stale files)
#   - cloudfront:CreateInvalidation on THIS distribution only
#
# It cannot: read objects, list other buckets, create invalidations on other
# distributions, or touch any other AWS service.

resource "aws_iam_policy" "deployer" {
  name        = "${var.cluster_name}-${var.environment}-deployer"
  description = "Least-privilege policy for the S3+CloudFront static-site deployer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = "s3:ListBucket"
        # ListBucket is a bucket-level action; the ARN must NOT include /*
        Resource = aws_s3_bucket.app.arn
      },
      {
        Sid    = "S3WriteDelete"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        # Object-level actions require the /* suffix
        Resource = "${aws_s3_bucket.app.arn}/*"
      },
      {
        Sid    = "CloudFrontInvalidate"
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        # Scoped to THIS distribution ARN only — not "*"
        Resource = aws_cloudfront_distribution.app.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

# ── Deployer IAM user (CI/CD machine identity) ────────────────────────────────
resource "aws_iam_user" "deployer" {
  name = "${var.cluster_name}-${var.environment}-deployer"
  path = "/ci/"

  tags = {
    Environment = var.environment
    Purpose     = "static-site-deployer"
  }
}

resource "aws_iam_user_policy_attachment" "deployer" {
  user       = aws_iam_user.deployer.name
  policy_arn = aws_iam_policy.deployer.arn
}
