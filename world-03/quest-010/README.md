# QUEST 010：DynamoDBの書庫を開け

## 🎯 QUEST概要

WORLD 3「データの王国」最初のクエスト。

DynamoDBのテーブルをTerraformで構築し、AWS CLIを使ってデータの登録・取得を行う。

今回はAIにTerraformコードを丸ごと生成させるのではなく、AIで調べながら自分でコードを書いてみた。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

- **AWSサービス**：Amazon DynamoDB
- **テーブル名**：`aws-quest-dev-quest-010-items`
- **Billing Mode**：`PAY_PER_REQUEST`
- **パーティションキー（PK）**：`adventurer_id`（String）
- **ソートキー（SK）**：`recorded_at`（String）
- **管理方法**：Terraform

今回のAWSリソースはDynamoDBテーブル1つのみ。

## 🧠 設計・設定で考えたこと

### 1. PKとSKの設計

冒険者の行動履歴を記録するテーブルを想定した。

- 冒険者IDと日時を指定して特定の記録を取得したい
- 冒険者IDを指定して行動履歴を時系列で取得したい

この2つの要件から、PKを`adventurer_id`、SKを`recorded_at`にした。

### 2. オンデマンド課金を採用

今回は短時間のハンズオンなので、読み書きのリクエスト量に応じて課金される`PAY_PER_REQUEST`を採用した。

なお、データ保存容量などは別途課金対象になる。

### 3. 命名規則を整理

過去のQUESTを見返したところ、AWSリソース名の付け方が統一されていなかった。

そこでWORLD 3からは、以下のルールを採用することにした。

- AWSリソース名：`{project}-{environment}-{quest-id}-{role}`
- Terraform内部のリソース名：`this`ではなく、役割が分かる名前を使う

今回のTerraform内部のリソース名は`records`とした。

## 🧪 実機検証

### TEST 1：Terraformでテーブル作成

TerraformでDynamoDBテーブルを定義し、`terraform plan`で作成内容を確認した後、`terraform apply`を実行。

**結果：成功**

### TEST 2：PutItemでデータ登録

AWS CLIの`put-item`を使用して、冒険者の行動記録を登録した。

**結果：成功**

### TEST 3：GetItemで1件取得

PKとSKを指定し、特定の行動記録を取得した。

**結果：成功**

### TEST 4：Queryで履歴を取得

PKに`hero-001`を指定してQueryを実行。

最初は`Count: 1`だったが、同じ冒険者の記録を追加して再実行すると、複数件取得できることを確認した。

さらに`--no-scan-index-forward`を指定すると、SKの降順で取得できた。

**結果：成功**

### TEST 5：Terraformでリソース削除

`terraform destroy`を実行。

**結果：成功**

## 💡 学んだこと

### GetItemとQueryの違い

- `GetItem`は複合主キーのPKとSKを指定して1件取得する
- `Query`はPKを指定して、同じPKの複数アイテムを取得できる
- `Query`ではSKによる並び順を変更できる

### DynamoDBは取得方法からキーを考える

単にデータを保存するだけでなく、どのような条件でデータを取得したいかを考えてPKとSKを決めることが重要。

### TerraformのattributeはRDBのカラム定義とは違う

今回の`attribute`ブロックで定義したのは、PKとSKに使用する属性のみ。

`action`などの通常のデータ属性は、テーブル作成時に定義する必要がなかった。

### AIを使って調べながら自分で書く

今回はAIを参考にしながら、自分でTerraformコードを書いた。

AIに全部生成してもらう方法とは違ったが、設定項目を自分で確認しながら書くことで、各パラメータの意味を考える機会になった。

## 🏁 RESULT

**QUEST 010 CLEAR！**

- DynamoDBテーブル構築
- PK・SK設計
- PutItem / GetItem / Queryの実機検証
- Terraformでの構築・削除完了

**WORLD 3「データの王国」最初のクエスト攻略完了！**