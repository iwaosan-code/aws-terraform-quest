# QUEST 012：S3のデータを検索せよ

## 🎯 QUEST概要

WORLD 3「データの王国」3つ目のクエスト。

今回はS3に保存したCSVファイルを、Amazon Athenaを使ってSQLで検索する。

QUEST 011ではDynamoDBのGSIを使って検索したが、今回はS3上のデータをSQLで直接検索・集計する仕組みを学ぶ。

TerraformでS3を構築し、AthenaとAWS Glue Data Catalogを組み合わせて動作を確認した。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

### 使用したAWSサービス

- **Amazon S3**：CSVデータとクエリ結果の保存
- **Amazon Athena**：SQLによる検索・集計
- **AWS Glue Data Catalog**：データベースと外部テーブルの定義

### S3の構成

バケット名：`aws-quest-dev-quest012-athena`

```text
aws-quest-dev-quest012-athena/
├── data/
│   └── adventure.csv
└── results/
    └── Athenaのクエリ結果
```

1つのS3バケットを使用し、プレフィックスによってデータとクエリ結果を分離した。

※ S3バケット名はグローバルで一意である必要があるため、実際の環境では変更する場合がある。

### Terraformで管理したリソース

- `aws_s3_bucket`
- `aws_s3_bucket_public_access_block`
- `aws_s3_bucket_server_side_encryption_configuration`

パブリックアクセスブロックは4項目すべて`true`に設定。

暗号化にはSSE-S3（`AES256`）を使用した。

### Athenaの設定

- データソース：`AwsDataCatalog`
- ワークグループ：`primary`
- データベース：`quest012`
- テーブル：`adventure`
- クエリ結果の保存先：`s3://<バケット名>/results/`

## 🧠 設計・設定で考えたこと

### 1. S3バケットは1つにする

最初に、データ用とクエリ結果用でS3バケットを分けるか、1つのバケットでプレフィックスを分けるかを検討した。

今回は構成をシンプルにするため、1つのバケットを採用した。

- `data/`：検索対象のCSV
- `results/`：Athenaのクエリ結果

S3のプレフィックスは実際のフォルダではなく、オブジェクトキーの一部。

事前にフォルダを作成しなくても、`data/adventure.csv`というキーでアップロードすればよい。

### 2. S3の公開を禁止する

AthenaがS3上のデータを読み取るために、バケットをパブリック公開する必要はない。

そこで、パブリックアクセスブロックを明示的に設定した。

また、S3は現在デフォルトでSSE-S3による暗号化が適用されるが、今回はTerraformで暗号化設定を管理する練習として明示的に定義した。

### 3. Athenaのテーブル定義と実データを分けて考える

AthenaはCSVを自身のストレージへ取り込むのではなく、S3上のデータを直接読み取る。

一方、テーブルの列構成やデータの保存場所などのメタデータは、AWS Glue Data Catalogに保存される。

つまり、S3・Athena・Glue Data Catalogが連携している。

## 🧪 実機検証

### TEST 1：TerraformでS3を構築

TerraformでS3バケット、パブリックアクセスブロック、暗号化設定を定義。

`terraform fmt`、`terraform validate`、`terraform plan`を実行した。

Planの結果は以下。

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

その後、`terraform apply`を実行。

**結果：成功**

### TEST 2：CSVをS3へアップロード

冒険者の行動履歴を記録した`adventure.csv`を作成した。

```csv
adventurer_id,recorded_at,action,exp
hero-001,2026-10-31T10:00:00Z,battle,100
hero-001,2026-10-31T11:00:00Z,explore,20
hero-002,2026-10-31T12:00:00Z,battle,150
hero-003,2026-10-31T13:00:00Z,rest,0
hero-003,2026-10-31T14:00:00Z,battle,200
```

AWS CLIで`data/adventure.csv`としてアップロード。

```powershell
aws s3 cp .\adventure.csv s3://<バケット名>/data/adventure.csv
```

`aws s3 ls`でファイルが配置されたことを確認した。

**結果：成功**

### TEST 3：Athenaのデータベース作成

AWSマネジメントコンソールからAthenaのクエリエディタを開き、クエリ結果の保存先を設定した。

```text
s3://<バケット名>/results/
```

続いて、データベースを作成。

```sql
CREATE DATABASE IF NOT EXISTS quest012;
```

**結果：成功**

### TEST 4：外部テーブルの作成

Athenaで以下のSQLを実行した。

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS quest012.adventure (
    adventurer_id STRING,
    recorded_at STRING,
    action STRING,
    exp INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://<バケット名>/data/'
TBLPROPERTIES (
    'skip.header.line.count'='1'
);
```

CSVの1行目はヘッダーなので、`skip.header.line.count`を`1`に設定した。

**結果：成功**

### TEST 5：全件検索

```sql
SELECT *
FROM quest012.adventure;
```

冒険者の行動履歴5件を検索した。

**結果：成功**

### TEST 6：条件検索

```sql
SELECT adventurer_id, recorded_at, exp
FROM quest012.adventure
WHERE action = 'battle'
ORDER BY recorded_at DESC;
```

`battle`の履歴を日時の降順で取得した。

想定される結果は以下。

| adventurer_id | recorded_at | exp |
|---|---|---:|
| hero-003 | 2026-10-31T14:00:00Z | 200 |
| hero-002 | 2026-10-31T12:00:00Z | 150 |
| hero-001 | 2026-10-31T10:00:00Z | 100 |

**結果：成功**

### TEST 7：集計

冒険者ごとの行動回数と獲得経験値を集計した。

```sql
SELECT
    adventurer_id,
    COUNT(*) AS action_count,
    SUM(exp) AS total_exp
FROM quest012.adventure
GROUP BY adventurer_id
ORDER BY total_exp DESC;
```

想定される結果は以下。

| adventurer_id | action_count | total_exp |
|---|---:|---:|
| hero-003 | 2 | 200 |
| hero-002 | 1 | 150 |
| hero-001 | 2 | 120 |

**結果：成功**

### TEST 8：クエリ統計を確認

Athenaのクエリ実行詳細から、集計SQLの統計情報を確認した。

| 項目 | 実測値 |
|---|---:|
| 実行時間 | 805ms |
| スキャンデータ量 | 0.24KB |

非常に小さなCSVだったため、スキャン量も少なかった。

ただし、Athenaはスキャン量に応じた課金体系であり、クエリごとの最低課金量などの条件がある。

今回の実測値だけで、大規模データに対する処理速度や料金を判断することはできない。

### TEST 9：リソースの削除

今回はTerraformで管理したリソース以外にも、Athena経由で作成したGlue Data Catalogの定義や、手動でアップロードしたCSVが存在した。

そのため、以下の順番で削除した。

1. Athenaの外部テーブルを削除
2. Athenaのデータベースを削除
3. S3のCSVとクエリ結果ファイルを削除
4. `terraform plan -destroy`で削除対象を確認
5. `terraform destroy`を実行

**結果：成功**

## 💡 学んだこと

### AthenaはS3のデータを直接検索できる

S3にCSVを置き、Athenaで外部テーブルを定義するだけでSQL検索できた。

データをRDBに取り込まなくても、検索や集計ができる。

### Glue Data Catalogはメタデータを管理する

今回、Athenaの画面から作成したデータベースやテーブル定義はGlue Data Catalogに登録された。

S3には実データ、Glue Data Catalogにはメタデータという役割分担になっている。

### DynamoDBとAthenaでは得意な処理が違う

QUEST 011では、DynamoDBのGSIを使って特定の行動履歴を効率的に検索した。

一方、今回のAthenaでは、SQLによって条件検索や集計を実行した。

- **DynamoDB**：キーを使った高速なデータ取得に向いている
- **Athena**：S3上のデータに対する分析や集計に向いている

同じ行動履歴データでも、用途によって適したサービスが変わることを実感した。

### Athenaはスキャン量を意識する必要がある

AthenaはSQLを書くだけで検索できるが、対象データの読み取り量が料金に関係する。

`WHERE`で返却件数を絞っただけでは、必ずしもスキャン量が減るわけではない。

今後は、パーティション分割やParquetなどの列指向フォーマットも学ぶと、より効率的な分析ができそう。

### Terraform管理外のリソースに注意する

今回はTerraformでS3を作成したが、AthenaのSQLで作成したGlue Data Catalogの定義はTerraformの管理対象外だった。

また、手動アップロードしたCSVやAthenaのクエリ結果も残る。

`terraform destroy`だけですべて片付くとは限らないことを確認できた。

## 🏁 RESULT

**QUEST 012 CLEAR！**

- TerraformでS3バケットを構築
- パブリックアクセスブロックと暗号化設定
- CSVをS3へアップロード
- Athenaで外部テーブルを定義
- SQLによる全件検索・条件検索・集計
- 実行時間805ms、スキャン量0.24KBを確認
- Glue Data Catalog・S3・Terraformの後片付け完了

**WORLD 3「データの王国」、3つ目のクエスト攻略完了！**