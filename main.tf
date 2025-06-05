resource "aws_route53_zone" "delegated" {
  name = var.delegated_domain
  tags = {
    Name = "terra-route53"
  }
}

resource "aws_route53_record" "delegated_ns" {
  zone_id = aws_route53_zone.delegated.zone_id
  name    = var.delegated_domain
  type    = "NS"
  ttl     = 300
  records = var.delegated_ns_records
}

resource "aws_acm_certificate" "tokyo" {
  provider          = aws.tokyo
  domain_name       = var.delegated_domain
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-tokyo"
  }
}

resource "aws_acm_certificate" "virginia" {
  provider          = aws.virginia
  domain_name       = var.delegated_domain
  validation_method = "DNS"
  tags = {
    Name = "terra-acm-virginia"
  }
}

// VPC
resource "aws_vpc" "main" {
  provider   = aws.tokyo
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terra-vpc"
  }
}

// サブネット
resource "aws_subnet" "public_a" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "terra-subnet-a"
  }
}

resource "aws_subnet" "public_c" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "terra-subnet-c"
  }
}

// インターネットゲートウェイ
resource "aws_internet_gateway" "gw" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "terra-igw"
  }
}

// ルートテーブル
resource "aws_route_table" "public" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "terra-rtb"
  }
}

resource "aws_route_table_association" "a" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "c" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "internet_access" {
  provider               = aws.tokyo
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

// セキュリティグループ
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
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "main" {
  provider   = aws.tokyo
  subnet_id  = aws_subnet.public_a.id
  security_group_ids = [aws_security_group.ec2.id]
  tags = {
    Name = "terra-ec2-ice"
  }
}

// EC2インスタンス
resource "aws_key_pair" "main" {
  provider   = aws.tokyo
  key_name   = "terra-key"
  public_key = var.public_key
  tags = {
    Name = "terra-key"
  }
}

resource "aws_instance" "web" {
  provider                  = aws.tokyo
  ami                       = "ami-0df99b3a8349462c6" // Amazon Linux 2 (ap-northeast-1)
  instance_type             = var.instance_type
  subnet_id                 = aws_subnet.public_a.id
  vpc_security_group_ids    = [aws_security_group.ec2.id]
  key_name                  = aws_key_pair.main.key_name
  associate_public_ip_address = true
  tags = {
    Name = "terra-ec2"
  }
}

// ELB
resource "aws_lb" "web" {
  provider = aws.tokyo
  name               = "terra-elb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  security_groups    = [aws_security_group.ec2.id]
  tags = {
    Name = "terra-elb"
  }
}

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

resource "aws_lb_listener" "https" {
  provider          = aws.tokyo
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.tokyo.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group_attachment" "web" {
  provider         = aws.tokyo
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

// CloudFront
resource "aws_cloudfront_distribution" "web" {
  provider = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "terra-cloudfront"
  aliases             = [var.delegated_domain]
  default_root_object = ""
  origins {
    domain_name = aws_lb.web.dns_name
    origin_id   = "terra-elb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "terra-elb"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.virginia.arn
    ssl_support_method  = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = {
    Name = "terra-cloudfront"
  }
}