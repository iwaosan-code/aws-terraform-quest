# QUEST 016：秘密を安全に保管せよ

## 目的

AWS Secrets Managerによる機密情報の保管・取得と、IAMによるアクセス制御を理解する。

## 使用サービス

- AWS Secrets Manager
- AWS Lambda
- AWS IAM
- Amazon CloudWatch Logs

## 構成

Secrets Managerにダミーのユーザー名とパスワードを格納し、2つのLambda関数から取得する。

Lambda関数は同一のPythonコードを使用し、IAMロールの権限のみを変更する。

- Lambda 1：シークレット取得権限あり
- Lambda 2：シークレット取得権限なし

## 動作確認結果

| 確認項目 | 結果 |
|---|---|
| Terraform apply | 11リソース作成 |
| Lambda 1 | シークレット取得成功 |
| Lambda 2 | アクセス拒否 |
| Terraform state | 機密値が平文で保存されることを確認 |
| マネコンからの機密値変更 | 成功 |
| 変更後のTerraform plan | No changes |
| シークレットのバージョン管理 | AWSCURRENT、AWSPREVIOUSを確認 |
| Terraform destroy | 11リソース削除 |

## 学んだこと

### IAMによるアクセス制御

GetSecretValueのみを許可し、対象リソースを特定のシークレットのARNに限定することで、最小権限を実現できる。

### Terraform stateの機密情報

Secrets Managerで機密情報を管理していても、secret_stringで指定した値はTerraform stateに保存される。

対策として、シークレットの入れ物だけをTerraformで管理し、機密値はマネジメントコンソールやAWS CLIから登録する方法がある。

### シークレットのバージョン管理

マネジメントコンソールから機密値を変更すると、新しいバージョンが作成される。

Terraformが管理しているバージョン自体は変更されないため、最新の機密値が変わってもTerraform planで差異が検出されない場合がある。

### リソース削除

学習用リソースのため、recovery_window_in_daysを0に設定した。

Lambdaの実行によって自動作成されたCloudWatch LogsのロググループはTerraformの管理外となるため、別途削除する。

## CLEAR条件

- [x] Secrets Managerの構築
- [x] シークレットの取得
- [x] IAMによるアクセス拒否
- [x] Terraform stateの機密情報リスクの理解
- [x] シークレットの復旧待機期間の理解
- [x] リソースの削除

## 基本方針

AI writes. Human decides.