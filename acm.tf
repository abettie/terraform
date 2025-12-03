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

# 画像用ACM証明書(本番用・バージニア北部)
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

# 画像用ACM証明書(テスト用・バージニア北部)
resource "aws_acm_certificate" "image_test" {
  provider          = aws.virginia
  domain_name       = var.image_domain_test
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-image-test"
  }
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

resource "aws_acm_certificate_validation" "image_test" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.image_test.arn
  validation_record_fqdns = [for record in aws_route53_record.image_test_cert_validation : record.fqdn]
}
