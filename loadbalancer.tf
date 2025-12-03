# Application Load Balancer
resource "aws_lb" "web" {
  provider           = aws.tokyo
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
