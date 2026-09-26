# QUEST 008：キューに仕事を預けよ

## 🎯 やったこと

- TerraformでS3 / SQS / Lambdaを構築
- S3のObject CreatedイベントをSQSへ送信
- `.txt` ファイルだけをSQSへ送るようにフィルタリング
- Lambda Event Source MappingでSQSをイベントソースとして設定
- LambdaからS3 Objectを取得して内容をCloudWatch Logsへ出力
- SQSのバッチ処理を確認
- Lambda失敗時のSQSリトライを確認
- Event Source Mappingを停止してキュー滞留を確認
- Event Source Mapping再開後、滞留メッセージが処理されることを確認
- terraform destroyまで実施

## 🧩 構成

```text
S3 Bucket
   │
   │ ObjectCreated (*.txt)
   ▼
SQS Queue
   │
   │ Event Source Mapping
   │ （Lambda側がpoll）
   ▼
Lambda
   │
   │ GetObject
   ▼
S3 Object
   │
   ▼
CloudWatch Logs
```

## 💡 学んだこと

### SQS → Lambdaの仕組み

S3やEventBridgeからLambdaを直接呼び出す場合とは異なり、
SQS自身がLambdaを直接Invokeするわけではない。

Lambda Event Source MappingがSQSをポーリングし、
取得したメッセージをLambdaへ渡す。

そのため、S3/EventBridgeで使用した
`aws_lambda_permission` は不要だった。

### Lambdaに必要なSQS権限

LambdaのExecution Roleに以下を設定した。

- `sqs:ReceiveMessage`
- `sqs:DeleteMessage`
- `sqs:GetQueueAttributes`

正常処理されたメッセージはSQSから削除される。

### S3 → SQSの権限

SQS Queue PolicyでS3からの `sqs:SendMessage` を許可した。

さらに以下で送信元を制限した。

- Principal：`s3.amazonaws.com`
- `aws:SourceArn`：対象S3 Bucket
- `aws:SourceAccount`：対象AWS Account

## 🧪 リトライを実機確認

S3 Notification設定時に送信された `s3:TestEvent` が
通常のS3 Event Notificationとは異なる形式だったため、
Lambdaで以下のエラーが発生した。

```text
KeyError: 'Records'
```

Lambdaが異常終了したためメッセージは削除されず、
SQSでは「処理中のメッセージ：1」の状態になった。

Visibility Timeout後にEvent Source Mappingから再取得され、
Lambdaが繰り返し実行されることを確認した。

Python側で `s3:TestEvent` を判定して正常に無視するよう修正。

```python
if s3_event.get('Event') == "s3:TestEvent":
    print("S3 Test Eventを受信しました。")
    continue
```

TerraformでLambdaを更新すると次回の再処理が成功し、
SQSの処理中メッセージが0になった。

```text
Lambda失敗
    ↓
メッセージは削除されない
    ↓
Visibility Timeout
    ↓
再度取得
    ↓
Lambda再実行
    ↓
修正後は成功
    ↓
メッセージ削除
```

## 📦 バッチ処理

`batch_size = 10` を設定。

11個のtxtファイルをまとめてアップロードしたところ、
Lambdaのログは複数に分かれて処理された。

`batch_size = 10` は
「10件溜まるまで待つ」という意味ではなく、
1回のLambda呼び出しで処理する最大メッセージ数であることを確認した。

SQS + Lambdaでは複数のLambda実行に分かれて
並列に処理される場合があることも確認した。

## 📨 キュー滞留を確認

Event Source Mappingを一時的に無効化。

```hcl
enabled = false
```

その状態で複数のtxtファイルをS3へアップロードすると、
Lambdaは起動せずSQSにメッセージが滞留した。

```text
S3
 ↓
SQS 📨📨📨📨📨
 ↓
× Event Source Mapping停止

Lambda
```

その後、

```hcl
enabled = true
```

に戻してTerraformをapply。

Event Source MappingがSQSのポーリングを再開し、
滞留していたメッセージがLambdaで処理された。

これにより、

**処理側が一時的に停止していてもSQSが仕事を保持し、
復旧後に処理を再開できる**

ことを実機で確認した。

## 🔄 EventBridgeとの違い

QUEST 007ではEventBridgeを使用した。

```text
S3
 ↓
EventBridge
 ↓ 条件に応じてルーティング
Lambda
```

QUEST 008ではSQSを使用した。

```text
S3
 ↓
SQS
 ↓ 仕事を保持
Lambda
```

EventBridgeは
**「イベントをどこへ流すか」**

SQSは
**「処理できるまで仕事を預かる」**

という役割の違いを実機で確認できた。

## 💥 ハマり・気づき

- SQSが空でもLambdaが起動するわけではない
- Event Source Mapping自身にIAM Roleを設定するのではなく、Lambda Execution RoleにSQS読み取り権限が必要
- S3/EventBridge → LambdaとSQS → Lambdaでは権限モデルが異なる
- S3 Test Eventと通常のS3 Event NotificationではJSON構造が異なる
- Lambdaが失敗するとSQSメッセージはすぐには削除されない
- Visibility Timeoutとリトライの関係を実際に確認できた
- `batch_size` は処理件数の固定値ではなく上限
- Event Source Mappingを止めることでSQSのバッファとしての役割を確認できた
- 手動アップロードしたS3 ObjectはTerraform管理外なのでdestroy前に削除が必要

## 🏁 RESULT

CLEAR