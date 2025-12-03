# Terraform状態保存用S3バケット
resource "aws_s3_bucket" "terraform_state" {
  provider = aws.tokyo
  bucket   = "terraform-state"

  # 誤って削除されないように保護（本番環境では true を推奨）
  force_destroy = true

  tags = {
    Name        = "terraform-state"
    Description = "Terraform state storage"
  }
}

# バージョニング有効化（状態ファイルの履歴を保持）
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Terraform状態ロック用DynamoDBテーブル
resource "aws_dynamodb_table" "terraform_lock" {
  provider     = aws.tokyo
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-state-lock"
    Description = "Terraform state locking"
  }
}
