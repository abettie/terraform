# VPC
resource "aws_vpc" "main" {
  provider                         = aws.tokyo
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    Name = "terra-vpc"
  }
}

# サブネットA
resource "aws_subnet" "public_a" {
  provider                        = aws.tokyo
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.1.0/24"
  availability_zone               = "ap-northeast-1a"
  map_public_ip_on_launch         = false
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "terra-subnet-a"
  }
}

# サブネットC
resource "aws_subnet" "public_c" {
  provider                        = aws.tokyo
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.2.0/24"
  availability_zone               = "ap-northeast-1c"
  map_public_ip_on_launch         = false
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
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
  provider               = aws.tokyo
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# インターネットへのIPv6ルート
resource "aws_route" "internet_access_ipv6" {
  provider                    = aws.tokyo
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.egress_only.id
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
