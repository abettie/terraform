# Terraform 構成手順

## 事前準備

1. [Terraformのインストール方法](./terraform-install.md) を参照してTerraformをインストールしてください。
2. [AWS CLI認証情報の設定方法](./aws-credentials.md) を参照してください。
3. Route53でホストゾーンを作成し、そのNSレコードをお名前ドットコムの管理画面で手動で設定してください（この作業はTerraformの処理対象外です）。
4. `variables.tf` の `delegated_domain`, `public_key` を適切に設定してください。

## 変数ファイルの作成

プロジェクトルートに `.gitignore` で管理外となる `terraform.tfvars` ファイルを作成し、以下のように記載してください。

```hcl
delegated_domain      = "example.com"
public_key            = "ssh-rsa AAAA..."
```

## 初期化

```sh
terraform init
```

## プラン作成

```sh
terraform plan
```

## 適用

```sh
terraform apply
```

## 注意

- ACM証明書のDNS検証が必要です。AWSコンソールで検証レコードを確認してください。
- ドメインのNSレコードを親ゾーンに設定してください。