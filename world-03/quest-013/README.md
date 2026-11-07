# QUEST 013：データカタログを編め

## 🎯 QUEST概要

WORLD 3「データの王国」4つ目のクエスト。

QUEST 012では、AthenaのSQLからAWS Glue Data Catalogのデータベースと外部テーブルを作成した。

今回は同じ仕組みをTerraformで管理し、データベース・テーブルの作成からスキーマ変更、削除までを実施する。

特に、Glue Data CatalogのメタデータとS3の実データの関係を確認する。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

### 使用したAWSサービス

- **Amazon S3**：CSVファイルの保存
- **AWS Glue Data Catalog**：データベースとテーブルのメタデータ管理
- **Amazon Athena**：SQLによるデータ検索

### 構成

```text
Terraform
├── Amazon S3
│   └── data/adventure.csv
└── AWS Glue Data Catalog
    ├── Database
    └── Table
        ├── Columns
        ├── CSV SerDe
        └── S3 Location
              ↓
          Amazon Athena
              ↓
          SQL検索
```

S3には実データを保存し、Glue Data Catalogにはデータの構造と保存場所を定義する。

AthenaはGlue Data Catalogのメタデータを参照して、S3上のCSVを検索する。

### Terraformで管理したリソース

| リソース | 用途 |
|---|---|
| `aws_s3_bucket` | CSV保存先 |
| `aws_s3_bucket_public_access_block` | パブリックアクセス禁止 |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3暗号化 |
| `aws_glue_catalog_database` | データベース |
| `aws_glue_catalog_table` | 外部テーブル |

今回は合計5リソースをTerraformで管理した。

CrawlerやETL Jobは使用していない。

## 🧠 設計・設定で考えたこと

### 1. GlueのデータベースとテーブルをTerraformで管理する

QUEST 012ではAthenaのSQLで以下を実行した。

- `CREATE DATABASE`
- `CREATE EXTERNAL TABLE`

今回はTerraformの`aws_glue_catalog_database`と`aws_glue_catalog_table`を使った。

テーブルからデータベースをリソース参照することで、Terraformが依存関係を把握できるようにした。

```hcl
database_name = aws_glue_catalog_database.quest013_database.name
```

### 2. CSVの読み取り方法を定義する

今回のCSVは、QUEST 012で使用した冒険者の行動履歴を再利用した。

```csv
adventurer_id,recorded_at,action,exp
hero-001,2026-10-31T10:00:00Z,battle,100
hero-001,2026-10-31T11:00:00Z,explore,20
hero-002,2026-10-31T12:00:00Z,battle,150
hero-003,2026-10-31T13:00:00Z,rest,0
hero-003,2026-10-31T14:00:00Z,battle,200
```

Glue Catalogのテーブルには、次の情報を定義した。

- S3の`data/`プレフィックス
- CSVの列名とデータ型
- カンマ区切りのSerDe設定
- ヘッダー1行のスキップ

### 3. Terraformの参照を利用する

GlueテーブルのS3保存場所には、Terraformで作成したバケットを参照させた。

```hcl
location = "s3://${aws_s3_bucket.quest013_bucket.bucket}/data/"
```

バケット名を直接書くのではなく、リソース参照にすることで、設定の重複を避けた。

## 🧪 実機検証

### TEST 1：Terraformのコードレビュー

S3、Glue Database、Glue Tableの定義を作成した。

`terraform validate`は成功。

ただし、最初のテーブル定義では、CSVの1列目が`adventurer_id`なのに対し、Terraform側では`adventure_id`としていた。

コードレビューで不一致に気づき、修正した。

**学び：`terraform validate`が成功しても、実データとの整合性までは保証されない。**

### TEST 2：Terraformで構築

`terraform plan`を実行。

```text
Plan: 5 to add, 0 to change, 0 to destroy.
```

想定した5リソースが作成対象であることを確認し、`terraform apply`を実行した。

**結果：成功**

### TEST 3：CSVをS3に配置

AWS CLIで`adventure.csv`をS3にアップロードした。

```powershell
aws s3 cp .\adventure.csv s3://<バケット名>/data/adventure.csv
```

最初はローカルファイルが見つからないエラーが発生した。

原因は、CSVを誤って`.terraform`ディレクトリ内にコピーしていたことだった。

ファイルを作業ディレクトリ直下へ配置し直し、アップロードに成功した。

### TEST 4：Athenaから検索

Terraformで作成したGlue Catalogのデータベースとテーブルを、Athenaから参照した。

最初はSQLで構文エラーが発生。

原因は、Glueのデータベース名にハイフンが含まれていたことだった。

通常のSELECT文では、ハイフンを含む識別子をダブルクォートで囲むことで解決した。

```sql
SELECT *
FROM "実際のデータベース名"."実際のテーブル名";
```

QUEST 012では`quest012`という名前だったため、この問題は発生しなかった。

**結果：検索成功**

### TEST 5：スキーマ変更のPlan差分

Glue Catalogのテーブル定義に、新しい列を追加した。

```hcl
columns {
  name = "bonus_exp"
  type = "int"
}
```

`terraform plan`を実行したところ、既存のGlue Tableが更新対象になった。

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

リソースの再作成ではなく、変更として認識されたことを確認した。

### TEST 6：スキーマ変更をApply

`terraform apply`で変更を反映した。

その後、Athenaから再検索したところ、`bonus_exp`列が追加されていた。

ただし、S3のCSVは変更していないため、追加列の値は空欄だった。

これは、CSVに該当する5列目が存在しないため、SQL上ではNULLとして扱われる状態。

**Glue Catalogのスキーマを変更しても、S3の実データは自動変更されないことを確認できた。**

### TEST 7：スキーマを元に戻す

Terraformから`bonus_exp`列を削除。

再びPlan差分を確認してApplyし、元の4列構成に戻した。

**結果：成功**

### TEST 8：Athenaのクエリ結果保存先

destroy前にS3を確認していたところ、Athenaのクエリ結果がQUEST 012で使用したバケットに保存されていることに気づいた。

原因は、前回のAthenaのクエリ結果保存先設定が残っていたこと。

Terraformで管理しているS3やGlue Catalogとは別に、Athena側にも設定が存在する。

**学び：Terraformでリソースを作り直しても、Terraform管理外の設定まで自動的に変更されるわけではない。**

### TEST 9：後片付けとdestroy

S3に保存したCSVとAthenaのクエリ結果を確認し、不要なオブジェクトを削除した。

削除対象の確認には、AWS CLIの`--dryrun`も利用できる。

```powershell
aws s3 rm s3://<バケット名>/ --recursive --dryrun
```

`--dryrun`を外すと実際に削除される。

S3の中身を片付けた後、Terraformで管理したリソースを削除した。

```powershell
terraform plan -destroy
terraform destroy
```

**結果：destroy成功**

## 💡 学んだこと

### Glue Data Catalogはデータそのものを保存するわけではない

Glue Data Catalogは、データの場所や構造などのメタデータを管理する。

実際のCSVはS3に保存されている。

この違いを、スキーマ変更によって確認できた。

### TerraformのPlan差分で変更内容を確認できる

今回の`bonus_exp`列の追加は、既存テーブルの変更として認識された。

Planを見ることで、適用前にどのリソースのどの設定が変更されるかを確認できる。

### スキーマ変更と実データの変更は別

Glue Catalogに列を追加しても、CSVにデータが増えるわけではない。

メタデータと実データを別々に管理することの意味を理解できた。

### AWSの命名規則は利用するサービスごとに考える

TerraformやGlueで利用できる名前でも、AthenaのSQLでは引用符が必要になる場合がある。

今後は、SQLで利用するデータベース名やテーブル名にアンダースコアを使うことも検討したい。

### Terraform管理外の設定にも注意する

今回のAthenaの結果保存先のように、前のクエストで設定した内容が残っていることがある。

Terraformで管理している範囲と、管理していない範囲を意識する必要がある。

## 🏁 RESULT

**QUEST 013 CLEAR！**

- TerraformでS3とGlue Catalogを構築
- AthenaからTerraform管理のテーブルを検索
- スキーマ変更のPlan差分を確認
- 追加列がNULLになることを確認
- スキーマを元に戻して再適用
- Athenaの保存先設定の持ち越しを発見
- S3の後片付けとTerraform destroyを完了

**WORLD 3「データの王国」、4つ目のクエスト攻略完了！**