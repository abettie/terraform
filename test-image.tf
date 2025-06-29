# バージニア北部リージョン用のACM証明書（テスト画像ドメイン）
resource "aws_acm_certificate" "image_test" {
  provider          = aws.virginia
  domain_name       = var.image_domain_test
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-image-test"
  }
}

# バージニア北部リージョン用ACM証明書のDNS検証
resource "aws_acm_certificate_validation" "image_test" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.image_test.arn
  validation_record_fqdns = [for record in aws_route53_record.image_test_cert_validation : record.fqdn]
}

resource "aws_route53_record" "image_test_cert_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.image_test.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.delegated.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}

# 画像用S3バケット（テスト用）
resource "aws_s3_bucket" "image_test" {
  provider = aws.tokyo
  bucket   = var.image_s3_bucket_test
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
  bucket = aws_s3_bucket.image_test.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "image_test" {
  bucket = aws_s3_bucket.image_test.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipalReadOnly"
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

# CloudFront OAC（テスト画像用S3バケット）
resource "aws_cloudfront_origin_access_control" "image_test" {
  provider = aws.virginia
  name                              = "terra-image-test-oac"
  description                       = "OAC for terra-image-test S3 bucket"
  origin_access_control_origin_type  = "s3"
  signing_behavior                   = "always"
  signing_protocol                   = "sigv4"
}

# テスト画像用CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "image_test" {
  provider = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-image-test-cloudfront"
  aliases             = [var.image_domain_test]
  default_root_object = ""
  origin {
    domain_name = aws_s3_bucket.image_test.bucket_regional_domain_name
    origin_id   = "terra-image-test-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.image_test.id
  }
  default_cache_behavior {
    target_origin_id             = "terra-image-test-s3"
    viewer_protocol_policy       = "redirect-to-https"
    allowed_methods              = ["GET", "HEAD"]
    cached_methods               = ["GET", "HEAD"]
    cache_policy_id              = aws_cloudfront_cache_policy.image.id
    compress                     = true
    response_headers_policy_id   = aws_cloudfront_response_headers_policy.image_403.id
  }
  ordered_cache_behavior {
    path_pattern           = "/thumbnails/*"
    target_origin_id       = "terra-image-test-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.image.id
    compress               = true
  }
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "terra-image-test-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.image.id
    compress               = true
  }
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.image_test.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_200"
  depends_on = [aws_acm_certificate_validation.image_test, aws_s3_bucket_acl.image_test]
  tags = {
    Name = "terra-image-test-cloudfront"
  }
}

# Route53レコード（image_domain_test用CloudFront）
resource "aws_route53_record" "image_test_cloudfront" {
  zone_id = data.aws_route53_zone.delegated.zone_id
  name    = var.image_domain_test
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.image_test.domain_name
    zone_id                = aws_cloudfront_distribution.image_test.hosted_zone_id
    evaluate_target_health = false
  }
}

