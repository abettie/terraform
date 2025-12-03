# CloudFrontログ保存用S3バケット
resource "aws_s3_bucket" "log" {
  provider      = aws.tokyo
  bucket        = "log-${var.sub_domain}"
  force_destroy = true
  tags = {
    Name = "terra-log"
  }
}

resource "aws_s3_bucket_ownership_controls" "log" {
  bucket = aws_s3_bucket.log.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log" {
  depends_on = [aws_s3_bucket_ownership_controls.log]
  bucket     = aws_s3_bucket.log.id
  acl        = "log-delivery-write"
}

# 画像用S3バケット(本番)
resource "aws_s3_bucket" "image" {
  provider      = aws.tokyo
  bucket        = var.image_s3_bucket
  force_destroy = true
  tags = {
    Name = "terra-image"
  }
}

resource "aws_s3_bucket_ownership_controls" "image" {
  bucket = aws_s3_bucket.image.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image" {
  depends_on = [aws_s3_bucket_ownership_controls.image]
  bucket     = aws_s3_bucket.image.id
  acl        = "private"
}

resource "aws_s3_bucket_policy" "image" {
  bucket = aws_s3_bucket.image.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.image.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.image.arn
          }
        }
      }
    ]
  })
}

# 画像用S3バケット(テスト)
resource "aws_s3_bucket" "image_test" {
  provider      = aws.tokyo
  bucket        = var.image_s3_bucket_test
  force_destroy = true
  tags = {
    Name = "terra-image-test"
  }
}

resource "aws_s3_bucket_ownership_controls" "image_test" {
  bucket = aws_s3_bucket.image_test.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_test" {
  depends_on = [aws_s3_bucket_ownership_controls.image_test]
  bucket     = aws_s3_bucket.image_test.id
  acl        = "private"
}

resource "aws_s3_bucket_policy" "image_test" {
  bucket = aws_s3_bucket.image_test.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.image_test.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.image_test.arn
          }
        }
      }
    ]
  })
}
