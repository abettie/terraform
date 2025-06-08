variable "delegated_domain" {
  description = "The domain name to delegate"
  type        = string
}

variable "aws_region_tokyo" {
  default     = "ap-northeast-1"
  description = "Tokyo region"
}

variable "aws_region_virginia" {
  default     = "us-east-1"
  description = "N. Virginia region"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "public_key" {
  description = "SSH public key for EC2"
  type        = string
}
