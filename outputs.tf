output "elb_dns_name" {
  value = aws_lb.web.dns_name
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.web.domain_name
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
