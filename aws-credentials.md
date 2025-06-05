# AWS CLI認証情報の設定方法

1. AWS CLIをインストールしてください（未インストールの場合）。
   - [公式インストールガイド](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)

2. 以下のコマンドを実行し、アクセスキー等を設定してください。

   ```sh
   aws configure
   ```

   - AWS Access Key ID, Secret Access Key, Default region name, Default output format を入力します。

3. 設定内容は `~/.aws/credentials` および `~/.aws/config` に保存されます。

4. 詳細は [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/cli-configure-quickstart.html) を参照してください。
