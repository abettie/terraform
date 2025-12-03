# デフォルトセキュリティグループ(自身からの全トラフィックのみ許可)
resource "aws_security_group" "default" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  name     = "terra-default-sg"
  tags = {
    Name = "terra-default-sg"
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
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
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
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
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
