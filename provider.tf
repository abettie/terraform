provider "aws" {
  alias  = "tokyo"
  region = var.aws_region_tokyo
}

provider "aws" {
  alias  = "virginia"
  region = var.aws_region_virginia
}
