# CloudFrontディストリビューション(Webアプリケーション用)
resource "aws_cloudfront_distribution" "web" {
  provider            = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-cloudfront"
  aliases             = [var.sub_domain]
  default_root_object = ""
  origin {
    domain_name = aws_lb.web.dns_name
    origin_id   = "terra-elb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  logging_config {
    bucket          = aws_s3_bucket.log.bucket_regional_domain_name
    include_cookies = false
    prefix          = "cloudfront-${var.sub_domain}/"
  }
  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "terra-elb"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = "83da9c7e-98b4-4e11-a168-04f0df8e2c65" # UseOriginCacheControlHeaders
    origin_request_policy_id   = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.virginia.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  depends_on = [aws_acm_certificate_validation.virginia, aws_s3_bucket_acl.log]
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_200"
  tags = {
    Name = "terra-cloudfront"
  }
}

# CloudFront OAC(画像用S3バケット・本番)
resource "aws_cloudfront_origin_access_control" "image" {
  provider                          = aws.virginia
  name                              = "terra-image-oac"
  description                       = "OAC for terra-image S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFrontディストリビューション(画像用・本番)
resource "aws_cloudfront_distribution" "image" {
  provider            = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-image-cloudfront"
  aliases             = [var.image_domain]
  default_root_object = ""
  origin {
    domain_name              = aws_s3_bucket.image.bucket_regional_domain_name
    origin_id                = "terra-image-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.image.id
  }
  default_cache_behavior {
    target_origin_id           = "terra-image-s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = aws_cloudfront_cache_policy.image.id
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.image_403.id
  }
  ordered_cache_behavior {
    path_pattern           = "/thumbnails/*"
    target_origin_id       = "terra-image-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.image.id
    compress               = true
  }
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "terra-image-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.image.id
    compress               = true
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.image.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_200"
  depends_on  = [aws_acm_certificate_validation.image, aws_s3_bucket_acl.image]
  tags = {
    Name = "terra-image-cloudfront"
  }
}

# CloudFrontキャッシュポリシー(1秒TTL)
resource "aws_cloudfront_cache_policy" "image" {
  provider    = aws.virginia
  name        = "terra-image-cache-policy"
  default_ttl = 1
  min_ttl     = 1
  max_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# 403用レスポンスヘッダポリシー(空ページ返却用)
resource "aws_cloudfront_response_headers_policy" "image_403" {
  provider = aws.virginia
  name     = "terra-image-403-policy"
  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "no-store"
      override = true
    }
  }
}

# CloudFront OAC(テスト画像用S3バケット)
resource "aws_cloudfront_origin_access_control" "image_test" {
  provider                          = aws.virginia
  name                              = "terra-image-test-oac"
  description                       = "OAC for terra-image-test S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFrontディストリビューション(テスト画像用)
resource "aws_cloudfront_distribution" "image_test" {
  provider            = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-image-test-cloudfront"
  aliases             = [var.image_domain_test]
  default_root_object = ""
  origin {
    domain_name              = aws_s3_bucket.image_test.bucket_regional_domain_name
    origin_id                = "terra-image-test-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.image_test.id
  }
  default_cache_behavior {
    target_origin_id           = "terra-image-test-s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = aws_cloudfront_cache_policy.image.id
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.image_403.id
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
    acm_certificate_arn      = aws_acm_certificate.image_test.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_200"
  depends_on  = [aws_acm_certificate_validation.image_test, aws_s3_bucket_acl.image_test]
  tags = {
    Name = "terra-image-test-cloudfront"
  }
}
