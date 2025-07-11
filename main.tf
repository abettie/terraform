# 東京リージョン用のACM証明書
resource "aws_acm_certificate" "tokyo" {
  provider          = aws.tokyo
  domain_name       = var.sub_domain
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-tokyo"
  }
}

# 東京リージョン用ACM証明書のDNS検証
resource "aws_acm_certificate_validation" "tokyo" {
  provider                = aws.tokyo
  certificate_arn         = aws_acm_certificate.tokyo.arn
  validation_record_fqdns = [for record in aws_route53_record.tokyo_cert_validation : record.fqdn]
}

# 東京リージョン用ACM証明書の検証レコード
resource "aws_route53_record" "tokyo_cert_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.tokyo.domain_validation_options : dvo.domain_name => {
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

# バージニアリージョン用のACM証明書
resource "aws_acm_certificate" "virginia" {
  provider          = aws.virginia
  domain_name       = var.sub_domain
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-virginia"
  }
}

# バージニアリージョン用ACM証明書のDNS検証
resource "aws_acm_certificate_validation" "virginia" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.virginia.arn
  validation_record_fqdns = [for record in aws_route53_record.tokyo_cert_validation : record.fqdn]
}

# 画像用ACM証明書（バージニア北部）
resource "aws_acm_certificate" "image" {
  provider          = aws.virginia
  domain_name       = var.image_domain
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-image"
  }
}

resource "aws_route53_record" "image_cert_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.image.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "image" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.image.arn
  validation_record_fqdns = [for record in aws_route53_record.image_cert_validation : record.fqdn]
}

# VPC
resource "aws_vpc" "main" {
  provider   = aws.tokyo
  cidr_block = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "terra-vpc"
  }
}

# サブネットA
resource "aws_subnet" "public_a" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
  ipv6_cidr_block         = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)}"
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "terra-subnet-a"
  }
}

# サブネットC
resource "aws_subnet" "public_c" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
  ipv6_cidr_block         = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)}"
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "terra-subnet-c"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "terra-igw"
  }
}

# Egress Only インターネットゲートウェイ
resource "aws_egress_only_internet_gateway" "egress_only" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "terra-egress-only-igw"
  }
}

# ルートテーブル
resource "aws_route_table" "public" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "terra-rtb"
  }
}

# インターネットへのIPv4ルート
resource "aws_route" "internet_access_ipv4" {
  provider                  = aws.tokyo
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.main.id
}

# インターネットへのIPv6ルート
resource "aws_route" "internet_access_ipv6" {
  provider                   = aws.tokyo
  route_table_id             = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id     = aws_egress_only_internet_gateway.egress_only.id
}

# サブネットAへのルートテーブル関連付け
resource "aws_route_table_association" "a" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# サブネットCへのルートテーブル関連付け
resource "aws_route_table_association" "c" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# デフォルトセキュリティグループ（自身からの全トラフィックのみ許可）
resource "aws_security_group" "default" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  name     = "terra-default-sg"
  tags = {
    Name = "terra-default-sg"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2用セキュリティグループ
resource "aws_security_group" "ec2" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  name     = "terra-ec2-sg"
  tags = {
    Name = "terra-ec2-sg"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# ELB用セキュリティグループ
resource "aws_security_group" "elb" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  name     = "terra-elb-sg"
  tags = {
    Name = "terra-elb-sg"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // 必要に応じてCloudFrontのIPレンジに制限可能
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "main" {
  provider   = aws.tokyo
  subnet_id  = aws_subnet.public_a.id
  security_group_ids = [aws_security_group.default.id]
  tags = {
    Name = "terra-ec2-ice"
  }
}

# EC2用キーペア
resource "aws_key_pair" "main" {
  provider   = aws.tokyo
  key_name   = "terra-key"
  public_key = var.public_key
  tags = {
    Name = "terra-key"
  }
}

# EC2インスタンス
resource "aws_instance" "web" {
  provider                  = aws.tokyo
  ami                       = "ami-027fff96cc515f7bc" // Amazon Linux 2023
  instance_type             = var.instance_type
  subnet_id                 = aws_subnet.public_a.id
  associate_public_ip_address = true
  vpc_security_group_ids    = [aws_security_group.default.id, aws_security_group.ec2.id]
  key_name                  = aws_key_pair.main.key_name
  user_data = <<-EOF
    #!/bin/bash
    sudo dnf -y upgrade
    sudo dnf -y install nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
  EOF
  tags = {
    Name = "terra-ec2"
  }
}

# ELB
resource "aws_lb" "web" {
  provider = aws.tokyo
  name               = "terra-elb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  security_groups    = [aws_security_group.default.id, aws_security_group.elb.id]
  tags = {
    Name = "terra-elb"
  }
}

# ELBターゲットグループ
resource "aws_lb_target_group" "web" {
  provider = aws.tokyo
  name     = "terra-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "terra-tg"
  }
}

# ELBリスナー(HTTPS)
resource "aws_lb_listener" "https" {
  provider          = aws.tokyo
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = aws_acm_certificate.tokyo.arn
  depends_on        = [aws_acm_certificate_validation.tokyo]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ELBターゲットグループへのアタッチ
resource "aws_lb_target_group_attachment" "web" {
  provider         = aws.tokyo
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "web" {
  provider = aws.virginia
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
    bucket = aws_s3_bucket.log.bucket_regional_domain_name
    include_cookies = false
    prefix = "cloudfront-${var.sub_domain}/"
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "terra-elb"
    compress = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "83da9c7e-98b4-4e11-a168-04f0df8e2c65" # UseOriginCacheControlHeaders
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.virginia.arn
    ssl_support_method  = "sni-only"
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

# CloudFrontログ保存用S3バケット
resource "aws_s3_bucket" "log" {
  provider = aws.tokyo
  bucket   = "log-${var.sub_domain}"
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

# S3バケットにACL設定
resource "aws_s3_bucket_acl" "log" {
  depends_on = [aws_s3_bucket_ownership_controls.log]
  bucket = aws_s3_bucket.log.id
  acl    = "log-delivery-write"
}

# サブドメイン用Route53レコード（CloudFront用）
resource "aws_route53_record" "sub_domain_cloudfront" {
  zone_id = data.aws_route53_zone.delegated.zone_id
  name    = var.sub_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53ゾーンIDを自動取得（ゾーン名から）
data "aws_route53_zone" "delegated" {
  name         = var.delegated_domain
  private_zone = false
}

# 画像用S3バケット
resource "aws_s3_bucket" "image" {
  provider = aws.tokyo
  bucket   = var.image_s3_bucket
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
  bucket = aws_s3_bucket.image.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "image" {
  bucket = aws_s3_bucket.image.id
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

# CloudFront OAC（画像用S3バケット）
resource "aws_cloudfront_origin_access_control" "image" {
  provider = aws.virginia
  name                              = "terra-image-oac"
  description                       = "OAC for terra-image S3 bucket"
  origin_access_control_origin_type  = "s3"
  signing_behavior                   = "always"
  signing_protocol                   = "sigv4"
}

# 画像用CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "image" {
  provider = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-image-cloudfront"
  aliases             = [var.image_domain]
  default_root_object = ""
  origin {
    domain_name = aws_s3_bucket.image.bucket_regional_domain_name
    origin_id   = "terra-image-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.image.id
  }
  default_cache_behavior {
    target_origin_id       = "terra-image-s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = aws_cloudfront_cache_policy.image.id
    compress               = true
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
    acm_certificate_arn            = aws_acm_certificate.image.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_200"
  depends_on = [aws_acm_certificate_validation.image, aws_s3_bucket_acl.image]
  tags = {
    Name = "terra-image-cloudfront"
  }
}

# CloudFrontキャッシュポリシー（1秒TTLに変更）
resource "aws_cloudfront_cache_policy" "image" {
  provider = aws.virginia
  name = "terra-image-cache-policy"
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
    enable_accept_encoding_gzip = true
    enable_accept_encoding_brotli = true
  }
}

# 403用レスポンスヘッダポリシー（空ページ返却用）
resource "aws_cloudfront_response_headers_policy" "image_403" {
  provider = aws.virginia
  name = "terra-image-403-policy"
  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "no-store"
      override = true
    }
  }
}

# Route53レコード（image_domain用CloudFront）
resource "aws_route53_record" "image_cloudfront" {
  zone_id = data.aws_route53_zone.delegated.zone_id
  name    = var.image_domain
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.image.domain_name
    zone_id                = aws_cloudfront_distribution.image.hosted_zone_id
    evaluate_target_health = false
  }
}