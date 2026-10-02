# MIMIC 002：サーバーレスの罠を見破れ

## 👹 MIMIC

AIが生成したS3 / SQS / Lambda構成のTerraformを、applyする前にコードレビューする。

構文上動くかどうかだけではなく、

- 権限が広すぎないか
- 不要な権限設定がないか
- AWSサービス間の連携方式が正しいか
- セキュリティ上の問題がないか
- 障害時の動作が考慮されているか

という観点から問題を探した。

## 🧩 要件

```text
S3
 │ .txt
 ▼
SQS
 │
 ▼
Lambda
 │
 ▼
S3 GetObject
 │
 ▼
CloudWatch Logs
```

S3へ `.txt` ファイルをアップロードするとSQSへ通知し、Lambdaでファイルを読み取る。

Lambdaが一時的に処理できない場合にもメッセージを失わない構成とする。

## 🔍 発見した問題

### 1. S3 Public Access Blockが無効

AI生成コードではすべて `false` になっていた。

```hcl
block_public_acls       = false
block_public_policy     = false
ignore_public_acls      = false
restrict_public_buckets = false
```

今回S3をPublicにする要件はないため、すべて `true` に修正した。

### 2. SQS Queue Policyが広すぎる

AI生成コードでは、

```hcl
Principal = "*"
Action    = "sqs:SendMessage"
Resource  = "*"
```

となっていた。

S3から対象SQS Queueへの送信だけを許可するよう修正した。

```text
Principal
└─ s3.amazonaws.com

Resource
└─ 対象SQS Queue

Condition
├─ aws:SourceArn     → 対象S3 Bucket
└─ aws:SourceAccount → 自AWS Account
```

### 3. Lambda Execution Roleが広すぎる

AI生成コードでは、

```hcl
Action   = "*"
Resource = "*"
```

となっていた。

必要な操作ごとに権限を分離した。

```text
S3
└─ s3:GetObject
   └─ 対象Bucket Objectのみ

SQS
├─ sqs:ReceiveMessage
├─ sqs:DeleteMessage
└─ sqs:GetQueueAttributes
   └─ 対象Queueのみ

CloudWatch Logs
└─ AWSLambdaBasicExecutionRole
```

### 4. S3 GetObject権限

LambdaはSQSメッセージからBucket / Object Keyを取得したあと、S3 Objectを読み取る。

そのため最小権限化する際にも、

```text
s3:GetObject
```

を忘れずに付与する必要がある。

### 5. 不要な aws_lambda_permission

AI生成コードには、

```text
SQS → Lambda
```

のための `aws_lambda_permission` が設定されていた。

しかしSQS連携では、Lambda Event Source MappingがSQSをポーリングする。

```text
SQS
 ▲
 │ Poll
 │
Lambda Event Source Mapping
 │
 ▼
Lambda
```

そのためS3 / EventBridgeからLambdaをPushで呼び出す場合とは異なり、SQS用の `aws_lambda_permission` は不要。

Lambda Execution Role側にSQSを読み取る権限が必要となる。

### 6. DLQがない

Lambdaが継続的に失敗すると、

```text
SQS
 ↓
Lambda 💥
 ↓
Visibility Timeout
 ↓
SQS
 ↓
Lambda 💥
 ↓
...
```

となり、同じメッセージが繰り返し処理される。

失敗し続けるメッセージを隔離するため、Dead Letter Queueを追加した。

## 💀 DLQ実験

Main QueueにRedrive Policyを設定した。

検証時間を短縮するため、

```text
Visibility Timeout = 10秒
maxReceiveCount    = 3
```

として実験した。

Lambda側では意図的にExceptionを発生させた。

```python
def lambda_handler(event, context):
    print("MIMIC: わざと処理を失敗させます")
    raise Exception("MIMIC: intentional failure")
```

S3へ `.txt` ファイルをアップロード。

```text
S3
 ↓
Main SQS
 ↓
Lambda 💥
 ↓
Visibility Timeout
 ↓
再試行 💥
 ↓
再試行 💥
 ↓
DLQ 💀
```

最終的にMain Queueからメッセージが移動し、DLQに格納されることを確認した。

## 💡 学んだこと

### applyできることと良いコードであることは別

Terraformとして成立するコードでも、

- Public Access
- 過剰権限
- 不要なPermission
- 障害時の設計不足

などの問題が存在する可能性がある。

`terraform validate` や `terraform plan` だけではなく、人間による設計レビューが必要。

### 権限は「誰が誰に何をするか」で考える

今回の構成では、

```text
S3
 │ SendMessage
 ▼
SQS
 ▲
 │ Receive / Delete / GetAttributes
 │
Lambda

Lambda
 │ GetObject
 ▼
S3
```

という関係になる。

サービスを接続するたびにIAM Roleを作るのではなく、

- IAM Policy
- Resource-based Policy
- Event Source Mapping
- Lambda Permission

など、連携方式によって必要な仕組みが異なる。

### リトライだけでは十分とは限らない

一時的な障害にはSQSのリトライが有効。

しかし永久に成功しないメッセージを繰り返し処理すると、正常な処理にも影響する。

DLQへ隔離することで、通常処理と失敗メッセージの調査を分離できる。

## 🧠 MIMICレビュー観点

今後AI生成Terraformをレビューするときは、

```text
① 公開範囲
② IAM / Resource Policy
③ サービス間の連携方式
④ 障害時の挙動
```

の順でも確認する。

## 🏁 RESULT

MIMIC DEFEATED 👹⚔️