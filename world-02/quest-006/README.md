# QUEST 006：S3 → Lambda

## 🎯 やったこと
- TerraformでS3とLambdaを構築
- S3 Event NotificationでObjectCreatedをLambdaのトリガーに設定
- Lambda Permissionで対象S3 BucketからのInvokeを許可
- LambdaのExecution Roleに対象Bucketへのs3:GetObjectを許可
- S3へファイルを手動アップロードしてLambdaの自動起動を確認
- LambdaからS3 Objectの内容を取得
- CloudWatch Logsでファイル名・ファイル内容を確認
- 日本語・空白を含むファイル名でも動作確認
- terraform destroyまで実施

## 🧩 構成

```text
S3 Bucket
   │ ObjectCreated
   │ Event Notification
   ▼
Lambda
   │
   ├─ Lambda Permission
   │    └─ 対象S3 BucketからのInvokeを許可
   │
   ├─ Execution Role
   │    ├─ s3:GetObject
   │    └─ CloudWatch Logs
   │
   ▼
CloudWatch Logs
```

## 💡 学んだこと
- S3 Event Notificationを使ってLambdaを直接起動できる
- S3 → LambdaのInvoke許可はLambda側のResource-based Policyで制御する
- Lambda → S3のアクセスはExecution RoleのIdentity-based Policyで制御する
- Lambdaへ渡されるS3イベントからBucket名とObject Keyを取得できる
- S3イベントのRecordsは配列。今回は1ファイルの動作確認なので先頭Recordのみ処理した
- S3イベントのObject KeyはURLエンコードされるため、urllib.parse.unquote_plus()でデコードして利用した
- 日本語・空白を含むファイル名でも正常にGetObjectできることを確認した
- Terraformでインフラを構築し、テストデータは手動投入する形に分離した

## 💥 ハマり
- 手動アップロードしたS3 ObjectはTerraform管理外だった
- Objectが残った状態でterraform destroyするとBucketNotEmptyでS3 Bucketの削除に失敗した
- Objectを手動削除してから再度terraform destroyして削除できた
- force_destroy = trueという選択肢もあるが、今回は使用しなかった

## 🏁 RESULT

CLEAR