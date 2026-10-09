# BOSS 002：非同期イベント基盤を設計せよ

## 👹 BOSS概要

WORLD 2「サーバーレスの森」の最終BOSS。

AWSサービスを指定されない状態で要件を読み、自分で構成を設計する。

設計した構成をTerraformで実装し、正常系だけでなく、業務停止・処理失敗・復旧まで実機検証する。

**攻略方針：AI writes. Human decides.**

## 📜 要件

社内担当者がアップロードしたテキストファイルを、複数の独立した業務で処理する仕組みを構築する。

- `.txt` ファイルを受け付け、外部には公開しない
- ファイル登録時に「内容確認」と「監査記録」の2業務へ通知する
- 一方の業務が停止しても、もう一方は処理を継続できる
- 停止中のメッセージを保持し、復旧後に処理できる
- 一時的な失敗は再試行し、繰り返し失敗するメッセージは隔離する
- 将来的な業務追加に対応できる
- 個人AWS環境で低コストに構築・削除できる

## 🏗️ 採用構成

```text
S3（.txt）
 │
 ▼
SNS Topic
 ├── Content SQS ── Content Lambda
 │       │               │
 │       └── Content DLQ  │ S3 GetObject
 │
 └── Audit SQS ─── Audit Lambda
         │
         └── Audit DLQ
```

### 使用したAWSサービス

| サービス | 用途 |
|---|---|
| S3 | ファイル受付・保存 |
| SNS | ファイル登録イベントのFanout配信 |
| SQS | 業務ごとのメッセージ保持 |
| Lambda | 内容確認・監査記録 |
| SQS DLQ | 繰り返し失敗するメッセージの隔離 |
| IAM | サービス間のアクセス制御 |
| CloudWatch Logs | 実行結果・エラーの確認 |

## 🧠 設計判断

### 1. SNS + SQSを採用

ファイル登録イベントを複数業務へ通知するため、SNSによるFanout構成を採用した。

業務ごとにSQSを設けることで、片方の処理が停止しても、もう片方に影響しない構成とした。

将来的に業務が増えた場合は、SNSの購読先としてSQSと処理用Lambdaを追加できる。

### 2. S3側でイベントをフィルタリング

当初は将来の拡張性を考慮し、SNS側でフィルタリングする案を検討した。

しかし、今回の要件は `.txt` ファイルのみであり、最小構成を優先してS3のイベント通知で `filter_suffix = ".txt"` を設定した。

将来的にファイル種別ごとの振り分けが必要になった場合は、通知方式を再検討する。

### 3. Standard Queueを採用

今回の要件では厳密な順序保証が必要ないため、Standard Queueを採用した。

Standard Queueでは重複配信の可能性があるため、実業務に拡張する場合は冪等性を考慮する必要がある。

FIFO Queueを使用しても、業務処理の厳密な一回実行が保証されるわけではない。

### 4. 業務ごとにDLQを配置

ContentとAuditそれぞれにDLQを設けた。

通常キューの `maxReceiveCount = 5` により、繰り返し受信されても正常に処理できないメッセージをDLQへ隔離する。

### 5. Lambdaの権限を分離

Content LambdaはS3のファイル内容を読み取るため、対象バケットへの `s3:GetObject` を許可する。

Audit Lambdaはイベント情報のみを記録するため、S3の読み取り権限を付与しない。

両Lambdaには、それぞれ担当するSQSの読み取り・削除に必要な権限を付与する。

## 🔍 AI生成Terraformのレビュー

AIが生成したTerraformをそのまま採用せず、既存QUESTとの一貫性と権限設定を確認した。

### 発見・修正した点

| 項目 | 対応 |
|---|---|
| AWS Provider | 既存QUESTの6系ではなく5系になっていたため修正 |
| IAM Policy Document | `principals` / `condition` のHCL構文を修正 |
| S3バケット名 | `bucket_prefix` の末尾ハイフンの意図を確認 |
| `required_version` | 追加された理由を確認 |
| Archive Provider | Lambda ZIP生成に必要な理由を確認 |
| Audit LambdaのIAM | S3読み取り権限が不要であることを確認 |
| SNS→SQS Policy | `aws:SourceArn` による送信元制限を確認 |

また、`ReportBatchItemFailures` の設定とPython実装が整合していることを確認した。

### 学んだこと

AI生成コードは、構文だけでなく既存の設計規約との整合性も確認する必要がある。

特にProviderのバージョン変更など、理由のない変更をそのまま採用しないことが重要。

## 🧪 実機検証

### TEST 1：正常系

S3へ `.txt` ファイルをアップロードした。

**結果：成功**

- SNS経由でContent / Audit両方のSQSへ通知された
- Content LambdaがS3からファイルを読み取り、内容をログ出力した
- Audit Lambdaがイベント名・バケット名・ファイル名をログ出力した

### TEST 2：片方の業務停止

Content LambdaのSQSトリガーを無効化した状態で、複数の `.txt` ファイルをアップロードした。

**結果：成功**

- Content SQSにメッセージが滞留した
- Audit側は停止せず処理を継続した
- Contentのトリガーを再有効化すると、滞留メッセージが処理された

トリガーの再有効化にはAWS CLIを使用した。

```powershell
aws lambda list-event-source-mappings --function-name <関数名> --no-cli-pager

aws lambda update-event-source-mapping --uuid <UUID> --enabled --no-cli-pager
```

### TEST 3：処理失敗とDLQ

Content Lambdaを一時的にExceptionを発生させるコードへ変更し、S3にファイルをアップロードした。

**結果：成功**

- Content Lambdaで処理失敗が発生した
- SQSから再試行された
- 繰り返し失敗したメッセージがContent DLQへ移動した

### TEST 4：DLQからの復旧

Content Lambdaを正常なコードへ戻し、DLQ Redriveでメッセージを元のContent SQSへ戻した。

**結果：成功**

- DLQから通常キューへメッセージを移動できた
- 復旧後のContent Lambdaで正常に処理できた

### TEST 5：Terraform差分・削除

検証後に `terraform plan` を実行したところ、Event Source Mappingの `metrics_config` に空配列と `null` の差分が表示された。

差分内容を確認し、今回の検証終了にあたって追加のapplyは不要と判断した。

その後、`terraform destroy` を実行した。

**結果：成功**

## 💡 学んだこと

### 非同期化による業務の独立性

SNSによるFanoutと業務ごとのSQSを組み合わせることで、一方の業務が停止しても、もう一方は処理を継続できる。

### 業務停止と処理失敗は異なる

トリガーを無効化した場合は、メッセージがSQSに滞留する。

Lambdaが失敗する場合は、Visibility Timeout後に再試行され、Redrive Policyの条件に達するとDLQへ移動する。

### DLQは隔離先であり、自動復旧の仕組みではない

Lambdaを復旧しても、DLQのメッセージは自動では通常キューへ戻らない。

原因を解消したうえで、DLQ Redriveなどによる再処理が必要になる。

### 要件を満たす最小構成を優先する

将来の拡張性は重要だが、現時点で不要な複雑さを持ち込まないことも設計判断のひとつ。

## 🏁 RESULT

**BOSS 002 CLEAR 👹⚔️**

- 要件からAWS構成を自分で設計
- AI生成Terraformをレビュー・修正
- 正常系・業務停止・再試行・DLQ隔離・復旧を検証
- Terraformで構築・削除完了

**WORLD 2：サーバーレスの森 COMPLETE！**