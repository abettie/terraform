# Terraformのインストール方法

1. 公式サイトからTerraformをダウンロードしてください。  
   [Terraform公式ダウンロードページ](https://developer.hashicorp.com/terraform/downloads)

2. ダウンロードしたzipファイルを解凍し、`terraform` バイナリをパスの通ったディレクトリ（例: `/usr/local/bin`）に配置してください。

   例（Linux/macOS）:
   ```sh
   unzip terraform_*.zip
   sudo mv terraform /usr/local/bin/
   terraform -v
   ```

3. `terraform -v` でバージョンが表示されればインストール完了です。

4. 詳細は [公式インストールガイド](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) を参照してください。
