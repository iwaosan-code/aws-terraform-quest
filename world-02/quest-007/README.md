# QUEST 007：EventBridgeの時を刻め

## 🎯 やったこと
- TerraformでS3 / EventBridge / Lambdaを構築
- S3のイベントをEventBridgeへ送信する設定を有効化
- EventBridge RuleでS3のObject Createdイベントをフィルタ
- `.txt` ファイルだけLambdaを起動する条件を設定
- Lambda Permissionで対象EventBridge RuleからのInvokeを許可
- LambdaからS3 Objectを取得して内容をCloudWatch Logsへ出力
- EventBridge RuleにCloudWatch LogsもTargetとして設定
- `.txt` ファイル2個でLambdaが起動することを確認
- `.jpg` ファイルではLambdaが起動しないことを確認
- terraform destroyまで実施

## 🧩 構成

```text
S3 Bucket
   │ Object Created
   ▼
EventBridge
   │
   │ Rule
   │ 対象Bucket + *.txt
   │
   ├────────────────┐
   ▼                ▼
Lambda          CloudWatch Logs
   │            （EventBridge Event）
   │ GetObject
   ▼
S3 Object
   │
   ▼
CloudWatch Logs
（Lambda実行ログ）
```

## 💡 学んだこと
- S3イベントをEventBridgeへ送信できる
- EventBridge RuleのEvent Patternでイベントをフィルタリングできる
- `suffix` 条件を使って `.txt` のObject Keyだけを対象にできる
- EventBridge Ruleと実際の処理先はTargetとして関連付ける
- EventBridge → LambdaのInvokeはLambdaのResource-based Policyで許可する
- `source_arn` を指定することで対象EventBridge RuleからのInvokeに限定できる
- EventBridgeを挟むことで、S3からLambdaへ直接通知する場合より柔軟にイベントを選別・ルーティングできる
- EventBridge経由ではS3イベントの構造が直接通知の場合と異なり、`detail` 配下からBucket名やObject Keyを取得する

## 🔐 権限で学んだこと
- Lambda → S3はExecution RoleのIdentity-based Policyで `s3:GetObject` を許可
- EventBridge → LambdaはLambda側のResource-based PolicyでInvokeを許可
- EventBridge → CloudWatch LogsではIAM Roleを用意するのではなく、CloudWatch Logs側のResource PolicyでEventBridgeからの書き込みを許可した
- 「誰が誰に何をするのか」を整理して権限方式を考える必要がある

## 🧪 動作確認

```text
*.txt
  ↓
S3 Object Created
  ↓
EventBridge Rule MATCH
  ├─ EventBridge Event → CloudWatch Logs
  └─ Lambda起動 → GetObject → CloudWatch Logs

*.jpg
  ↓
S3 Object Created
  ↓
EventBridge Rule NO MATCH
  ↓
Lambdaは起動しない
```

## 💥 ハマり・気づき
- EventBridge → CloudWatch LogsにIAM Roleが必要だと考えたが、Resource Policyを使う構成だった
- TerraformではRule / Target / Permission / Resource Policyなど、マネジメントコンソールでは意識しにくい構成要素が明示的に見える
- 手動アップロードしたS3 ObjectはTerraform管理外なのでdestroy前に手動削除した
- Terraformで明示的に作成したEventBridge用CloudWatch Log Groupはdestroy時に削除された
- AWS上に存在するリソースでも、Terraform管理・AWSによる自動生成・手動作成ではライフサイクル管理が異なる

## 🏁 RESULT

CLEAR