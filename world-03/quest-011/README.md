# QUEST 011：索引の秘密を解け

## 🎯 QUEST概要

WORLD 3「データの王国」2つ目のクエスト。

QUEST 010で構築したDynamoDBのテーブルを発展させ、GSI（グローバルセカンダリインデックス）を追加する。

今回は、アクセスパターンからGSIを設計し、ScanとQueryの違いを実機で確認する。

さらに、SQLライクにDynamoDBを操作できるPartiQLも試してみた。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

- **AWSサービス**：Amazon DynamoDB
- **テーブル名**：`aws-quest-dev-quest-011-records`
- **Billing Mode**：`PAY_PER_REQUEST`
- **管理方法**：Terraform

### 元のテーブル

| キー | 属性 | 型 |
|---|---|---|
| PK | `adventurer_id` | String |
| SK | `recorded_at` | String |

### 追加したGSI

| 項目 | 設定 |
|---|---|
| GSI名 | `action-index` |
| PK | `action` |
| SK | `recorded_at` |
| Projection | `ALL` |

※ GSI名はTerraformの`local.dynamodb_GSI_name`で管理。

## 🧠 設計・設定で考えたこと

### 1. アクセスパターンからGSIを設計

今回想定したのは、冒険者の行動履歴を管理するテーブル。

取得したいデータは2種類。

- 特定の冒険者の行動履歴を取得する
- 全冒険者の中から、特定の行動の履歴を取得する

元のテーブルは`adventurer_id`がPKなので、冒険者単位の検索には向いている。

しかし、`action = battle`のような条件で検索したい場合、元のキー構成では効率的にQueryできない。

そこで、`action`をPKとするGSIを追加することにした。

### 2. GSIにもSKを設定

GSIのSKには`recorded_at`を採用した。

理由は、特定の行動履歴を日時順に取得したかったから。

これにより、例えば`battle`の履歴を新しい順に取得できる。

### 3. GSIの追加前後で比較する

今回のCLEAR条件には、GSI追加時のTerraform差分確認がある。

そのため、最初からGSI付きのテーブルを作るのではなく、以下の順番で構築した。

1. GSIなしのテーブルを作成
2. テストデータを登録
3. Scanで検索
4. TerraformにGSIを追加
5. `terraform plan`で差分を確認
6. `terraform apply`でGSIを追加
7. GSIを使ってQuery

## 🧪 実機検証

### TEST 1：GSIなしのテーブルを構築

TerraformでDynamoDBテーブルを作成。

`terraform plan`で内容を確認した後、`terraform apply`を実行した。

**結果：成功**

### TEST 2：テストデータを登録

AWS CLIの`put-item`を使用し、以下の6件を登録した。

| adventurer_id | recorded_at | action |
|---|---|---|
| hero-001 | 2026-10-24T10:00:00Z | battle |
| hero-001 | 2026-10-24T11:00:00Z | explore |
| hero-002 | 2026-10-24T12:00:00Z | battle |
| hero-002 | 2026-10-24T13:00:00Z | rest |
| hero-003 | 2026-10-24T14:00:00Z | battle |
| hero-003 | 2026-10-24T15:00:00Z | explore |

**結果：6件登録成功**

### TEST 3：Scanでbattleの履歴を取得

GSIがない状態で、`action = battle`を条件にScanを実行した。

**実測結果**

- `Count`：3
- `ScannedCount`：6

取得したかったデータは3件だが、実際には6件を読み取っていた。

ScanのFilterExpressionは、読み取ったデータに対してフィルターを適用するため、返却件数が少なくても読み取り対象が減るわけではない。

### TEST 4：PartiQLで検索

DynamoDBのCLI操作はJSONや式の指定が多く、少し面倒だった。

SQLライクに書けないかと思って調べたところ、PartiQLが使えることが分かった。

試したSQLは以下。

```sql
SELECT *
FROM "aws-quest-dev-quest-011-records"
WHERE "action" = 'battle'
```

最初は`Unexpected keyword`というエラーが発生。

さらに、JSONファイルを使う方法でも`Invalid JSON received`が発生した。

最終的には、PowerShellの`ConvertTo-Json`でJSONを生成し、AWS CLIの`--cli-input-json`で実行することで成功した。

**結果：成功**

ただし、SQLライクに記述できても、キー条件を利用しない検索はScan相当になる。

書き方が変わっても、DynamoDBのキー設計が不要になるわけではない。

### TEST 5：TerraformでGSIを追加

Terraformに以下の定義を追加した。

```hcl
attribute {
  name = "action"
  type = "S"
}

global_secondary_index {
  name            = local.dynamodb_GSI_name
  hash_key        = "action"
  range_key       = "recorded_at"
  projection_type = "ALL"
}
```

`terraform validate`は成功。

`terraform plan`でも既存テーブルへの更新として処理されることを確認した。

ただし、`hash_key`と`range_key`にDeprecated警告が表示された。

構文は有効だったため、今回は警告を記録して先に進めた。

GSI追加の`terraform apply`では、更新完了までかなり時間がかかった。

テストデータが6件でも、GSIの作成はすぐに終わるとは限らないことを実感した。

**結果：GSI追加成功**

### TEST 6：GSIを使ってQuery

GSIのPKである`action`に`battle`を指定してQueryを実行。

さらに、`--no-scan-index-forward`で降順取得を試した。

**実測結果**

- `Count`：3
- `ScannedCount`：3

取得順序は以下のとおり。

1. hero-003：14:00
2. hero-002：12:00
3. hero-001：10:00

GSIのPKで対象を検索し、SKによる降順取得ができることを確認した。

### TEST 7：ScanとGSI Queryを比較

| 項目 | Scan | GSI Query |
|---|---|---|
| Count | 3 | 3 |
| ScannedCount | 6 | 3 |
| 検索方法 | テーブルを走査 | GSIのキーで検索 |
| 取得順序 | 順序保証なし | SK順で取得可能 |

同じ3件を取得する場合でも、ScanとQueryでは検索方法が違う。

今回の少量データではコストや速度の優劣までは評価できないが、キーを利用することの意味を確認できた。

※ `ScannedCount`は読み取ったアイテム数を表し、消費RCUや料金そのものではない。

### TEST 8：Terraformでリソース削除

`terraform plan -destroy`で削除対象を確認した後、`terraform destroy`を実行。

**結果：成功**

## 💡 学んだこと

### DynamoDBはアクセスパターンから設計する

RDBのように自由な検索を前提とするのではなく、どのような条件でデータを取得したいかを先に考えることが重要。

元のテーブルのキーだけでは対応しにくい検索には、GSIが有効な選択肢になる。

### GSIは別の検索経路を作る仕組み

今回は`action`をGSIのPKにしたことで、冒険者IDを指定せずに行動種別でQueryできるようになった。

さらに`recorded_at`をSKにすることで、日時順の取得にも対応できた。

ただし、GSIには追加の保存容量や読み書きコストが発生するため、必要なアクセスパターンに合わせて設計する必要がある。

### ScanとQueryは検索の仕組みが違う

今回の実測では、Scanの`ScannedCount`は6、GSI Queryは3だった。

データ件数が増えた場合、この違いはより重要になる。

### GSI追加は時間がかかる場合がある

Terraform上ではインプレース更新でも、AWS側ではGSIの準備や既存データの反映が行われる。

設定変更だからといって、すぐに終わるとは限らない。

### PartiQLは便利だが万能ではない

SQLライクに書けるのは便利。

一方で、検索効率はキー設計やアクセス方法に依存する。

また、PowerShell・AWS CLI・JSONの受け渡しでハマったので、SQLそのものと引数・ファイル形式の問題を切り分ける重要性も学んだ。

## ⚠️ 未解決事項

### TerraformのDeprecated警告

GSI定義の`hash_key`と`range_key`にDeprecated警告が表示された。

`terraform validate`と`terraform plan`は成功し、実際のGSI追加も完了したが、警告の発生理由や今後の推奨構文は未確認。

AWS Providerのバージョンとスキーマを確認する必要がある。

## 🏁 RESULT

**QUEST 011 CLEAR！**

- アクセスパターンからGSIを設計
- ScanとQueryの違いを実測
- GSIのPK・SKによる検索と並び替えを確認
- TerraformでGSI追加時の差分を確認
- PartiQLによるSQLライクな検索を体験
- Terraformで構築・削除完了

**WORLD 3「データの王国」、2つ目のクエスト攻略完了！**