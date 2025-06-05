# Terraform 構成手順

## 事前準備

1. [AWS CLI認証情報の設定方法](./aws-credentials.md) を参照してください。
2. `variables.tf` の `delegated_domain`, `delegated_ns_records`, `public_key` を適切に設定してください。

## 初期化

```sh
terraform init
```

## プラン作成

```sh
terraform plan \
  -var 'delegated_domain=example.com' \
  -var 'delegated_ns_records=["ns-xxxx.awsdns-xx.com.","ns-yyyy.awsdns-yy.net."]' \
  -var 'public_key=ssh-rsa AAAA...'
```

## 適用

```sh
terraform apply
```

## 注意

- ACM証明書のDNS検証が必要です。AWSコンソールで検証レコードを確認してください。
- ドメインのNSレコードを親ゾーンに設定してください。