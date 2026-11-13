# QUEST 014：データ変更を伝令せよ

## 🎯 QUEST概要

WORLD 3「データの王国」の連携技クエスト。

DynamoDB StreamsとLambdaを連携させ、DynamoDBのデータ変更を検知して非同期処理する仕組みをTerraformで構築した。

今回はQUEST 010で使用した「冒険者の行動履歴」のデータ構造を引き継ぎ、アイテムの追加・更新・削除がLambdaにどのように伝わるのかを確認した。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

**AWSサービス**
- Amazon DynamoDB
- DynamoDB Streams
- AWS Lambda
- AWS IAM
- Amazon CloudWatch Logs

**DynamoDBテーブル**
- テーブル名：`aws-quest-dev-quest-014-items`
- 課金方式：`PAY_PER_REQUEST`
- PK：`adventurer_id`（String）
- SK：`recorded_at`（String）
- Streams：`NEW_AND_OLD_IMAGES`

**Lambda**
- ランタイム：Python 3.13
- バッチサイズ：10
- ストリーム読み取り開始位置：`LATEST`

**Terraform管理リソース**
1. DynamoDBテーブル
2. IAM Role
3. IAM Policy Attachment
4. Lambda関数
5. Lambda Event Source Mapping

## 🧠 設計・設定で考えたこと

### 1. DynamoDB StreamsとLambdaの連携

DynamoDBがLambdaを直接呼び出すのではなく、LambdaのEvent Source MappingがStreamsをポーリングして変更イベントを取得する。

取得したイベントはLambdaにまとめて渡される場合があるため、Python側では`Records`をループ処理するようにした。

### 2. Streamsの記録内容

更新前後のデータを比較するため、`NEW_AND_OLD_IMAGES`を採用。

これにより、INSERT・MODIFY・REMOVEのイベントに加えて、変更前後のデータを確認できる。

### 3. IAM Roleの利用

LambdaにはIAM Roleを設定し、DynamoDB Streamsの読み取りとCloudWatch Logsへの書き込みを許可した。

LambdaサービスがRoleを引き受け、一時的な認証情報を使用してAWSリソースにアクセスする仕組みを確認した。

### 4. Event Source Mappingの設定

`starting_position = "LATEST"`を指定した。

これにより、新しく発生する変更イベントを処理対象とする。

`batch_size = 10`は最大10件をまとめて処理できる設定であり、必ず10件たまるまで待つわけではない。

## 🧪 実機検証

### TEST 1：Terraformによる構築

`terraform plan`を実行。

**結果：5 to add, 0 to change, 0 to destroy**

続けて`terraform apply`を実行し、リソースを構築した。

**結果：成功**

### TEST 2：INSERTイベント

AWS CLIの`put-item`で冒険者の行動履歴を登録。

CloudWatch Logsに`INSERT`イベントが出力されることを確認した。

**結果：成功**

### TEST 3：MODIFYイベント

`update-item`で`action`を変更。

- 変更前：`quest-start`
- 変更後：`quest-complete`

CloudWatch Logsで`MODIFY`イベントと、`OldImage`・`NewImage`の両方を確認できた。

**結果：成功**

### TEST 4：REMOVEイベント

`delete-item`でアイテムを削除。

CloudWatch Logsで以下を確認した。

- `eventName`：`REMOVE`
- `OldImage`：削除前のデータ
- `NewImage`：`null`

**結果：成功**

### TEST 5：Terraformによる削除

`terraform destroy`を実行。

**結果：成功**

## 💡 学んだこと

### DynamoDB Streamsは変更イベントを記録する

DynamoDB Streamsを有効にすると、アイテムの追加・更新・削除をイベントとして取得できる。

Lambdaとの接続にはEvent Source Mappingを使用する。

### Lambdaのイベント処理は重複する可能性がある

Lambdaのイベント処理が失敗すると、イベントが再試行される場合がある。

そのため、同じイベントが複数回処理されても、結果が変わらない設計が重要になる。

### eventIDと冪等性

重複処理を防ぐ方法として、処理済みの`eventID`をDynamoDBに記録する方法を考えた。

ただし、単に処理済みIDを記録するだけでは不十分。

- 本処理の後にIDを記録すると、途中で失敗した場合に二重処理される可能性がある
- IDを先に記録すると、途中で失敗した場合に本処理が実行されない可能性がある

そこで、DynamoDBの`TransactWriteItems`を利用し、本処理と処理済みIDの記録を1つのトランザクションにまとめる方法を学んだ。

今回は実装せず、設計上の理解までとした。

### トランザクションと強い整合性の違い

トランザクションは複数の更新をまとめて成功・失敗させる仕組み。

強い整合性のある読み取りは、成功済みの最新の書き込み結果を読み取るための仕組み。

両者は異なる役割を持っていることを整理できた。

## 🏁 RESULT

**QUEST 014 CLEAR！**

- DynamoDB StreamsとLambdaの連携を構築
- INSERT・MODIFY・REMOVEのイベントを確認
- 変更前後のデータを確認
- 再試行と冪等性について理解
- Terraformによる構築・削除完了

DynamoDBのデータ変更を起点に、非同期処理を実行する仕組みを体験できた。