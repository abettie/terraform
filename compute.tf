# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "main" {
  provider           = aws.tokyo
  subnet_id          = aws_subnet.public_a.id
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
  provider                    = aws.tokyo
  ami                         = "ami-027fff96cc515f7bc" // Amazon Linux 2023
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.default.id, aws_security_group.ec2.id]
  key_name                    = aws_key_pair.main.key_name
  user_data                   = <<-EOF
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
