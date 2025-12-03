# Route53ゾーンIDを自動取得(ゾーン名から)
data "aws_route53_zone" "delegated" {
  name         = var.delegated_domain
  private_zone = false
}

# サブドメイン用Route53レコード(CloudFront用)
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

# Route53レコード(画像ドメイン用CloudFront・本番)
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

# Route53レコード(画像ドメイン用CloudFront・テスト)
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
