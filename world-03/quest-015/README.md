# QUEST 015：RDSの書庫を開け

## 🎯 QUEST概要

WORLD 3「データの王国」のクエスト。

Amazon RDS for PostgreSQLをTerraformで構築し、VPC・Privateサブネット・セキュリティグループとの関係を確認した。

Session Managerを利用してPrivate EC2に接続し、そこからRDSへの接続、テーブル作成、データの読み書きを実施した。

さらに、TerraformによるRDSの設定変更と、既存データへの影響を検証した。

**攻略方針：AI writes. Human decides.**

## 🏗️ 構築したもの

**AWSサービス**
- Amazon VPC
- Amazon EC2
- Amazon RDS for PostgreSQL
- AWS Systems Manager（Session Manager）
- AWS IAM
- VPCエンドポイント

**ネットワーク構成**
- VPC内にPrivateサブネットを複数AZで配置
- RDSはシングルAZ構成
- EC2とRDSはPrivateサブネットに配置
- Session Manager用のInterface型VPCエンドポイントを利用
- EC2からRDSへTCP 5432で接続

**RDS**
- エンジン：PostgreSQL 15.19
- インスタンス：`db.t3.micro`
- ストレージ：20 GiB / gp3
- Multi-AZ：無効
- パブリックアクセス：無効
- 削除保護：無効
- 最終スナップショット：取得しない

**EC2**
- OS：Amazon Linux 2023
- インスタンス：`t3.micro`
- 接続：Session Manager
- IAM管理ポリシー：`AmazonSSMManagedInstanceCore`

## 🧠 設計・設定で考えたこと

### 1. RDSのPrivate配置

RDSをインターネットから直接アクセスできないPrivate環境に配置した。

EC2もPrivateサブネットに配置し、Session Manager経由でアクセスする構成とした。

同一VPC内のEC2とRDSは、ルートテーブルのlocalルートで通信できるため、両者の通信にNAT Gatewayは不要。

### 2. DBサブネットグループ

異なるAZのPrivateサブネットをDBサブネットグループに登録した。

シングルAZ構成でも、DBサブネットグループには複数AZのサブネットを指定する。

DBサブネットグループの指定と、Multi-AZ構成の有効化は別の設定であることを確認した。

### 3. セキュリティグループ

用途ごとにSGを分離した。

- EC2：インバウンドなし、アウトバウンド全許可
- SSMエンドポイント：EC2のSGからTCP 443を許可
- RDS：EC2のSGからTCP 5432を許可

SGがステートフルであるため、許可された通信に対する応答は、逆方向のルールがなくても通過できる。

### 4. Session ManagerとIAM

EC2にIAMロールとインスタンスプロファイルを関連付けた。

`AmazonSSMManagedInstanceCore` を付与し、SSHポートを開放せずにEC2へ接続できることを確認した。

SSM用のInterface型VPCエンドポイントには、`ssm` と `ssmmessages` を利用した。

### 5. PostgreSQLのバージョン取得

`aws_rds_engine_version` データソースを使用した。

当初はメジャーバージョンを指定せず、最新バージョンを取得したところ18.6が選択された。

その後、15系に限定して取得し、15.19を使用した。

最新バージョンが必ずしもインスタンスタイプと互換性を持つわけではないため、組み合わせの確認が重要になる。

## 🧪 実機検証

### TEST 1：Terraformによる構築

`terraform plan` を実行。

**結果：20 to add, 0 to change, 0 to destroy**

最初のapplyでは、RDSのマスターユーザー名に予約語の`admin`を指定していたためエラーが発生した。

ユーザー名を変更し、再度applyを実行した。

**結果：構築成功**

### TEST 2：Session ManagerによるEC2接続

マネジメントコンソールからPrivate EC2へのSession Manager接続を実施。

SSHやパブリックIPを使用せず、シェルに接続できた。

**結果：成功**

### TEST 3：PostgreSQLへの接続

EC2にPostgreSQLクライアントをインストールし、`psql`を使用してRDSへ接続した。

RDSのエンドポイントを接続先として指定し、マスターユーザーの認証に成功した。

**結果：成功**

### TEST 4：テーブル作成・データ読み書き

以下のテーブルを作成した。

```sql
CREATE TABLE quest_log (
    id SERIAL PRIMARY KEY,
    quest_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL
);
```

続けてデータを登録。

```sql
INSERT INTO quest_log (quest_name, status)
VALUES ('QUEST 015', 'IN_PROGRESS');
```

SELECTで登録内容を確認した。

```sql
SELECT * FROM quest_log;
```

**結果：成功**

### TEST 5：TerraformによるRDS設定変更

バックアップ保持期間を変更した。

```hcl
backup_retention_period = 0
```

↓

```hcl
backup_retention_period = 1
```

`terraform plan`で、RDSが再作成ではなく既存リソースの更新となることを確認した。

最初のapply後、マネジメントコンソールで設定が「保留中の変更」となっていることを確認。

そのため、以下を追加した。

```hcl
apply_immediately = true
```

再度applyすることで、バックアップ保持期間が1日に変更された。

**結果：成功**

### TEST 6：設定変更後のデータ確認

RDSに再接続し、`quest_log`テーブルをSELECTした。

設定変更前にINSERTしたデータが残っていることを確認した。

**結果：成功**

### TEST 7：Terraformによる削除

`terraform plan -destroy`を実行。

**結果：0 to add, 0 to change, 21 to destroy**

その後、`terraform destroy`を実行。

**結果：削除成功**

## 💡 学んだこと

### RDSはEC2とは管理方法が異なる

RDSではOSにログインするのではなく、データベースのエンドポイントに対してDBクライアントから接続する。

今回はSession Manager経由でEC2に接続し、そこからPostgreSQLにアクセスした。

### SGは通信の方向と開始元を意識する

EC2が通信を開始する場合、EC2側のアウトバウンドと、接続先のインバウンドを許可する。

SGはステートフルなので、戻りの通信を個別に許可する必要はない。

### Terraformのapply成功と設定反映は別

RDSの設定変更では、Terraformのapplyが完了しても変更が保留される場合がある。

`apply_immediately`の設定によって、即時反映するかどうかを制御できる。

また、再作成を伴わない変更でも、一時的にDBが利用できなくなる可能性がある。

### 設定変更とデータの保持

バックアップ保持期間の変更は、RDSを再作成せずに実施できた。

変更後も既存のテーブルとデータが残っていた。

### RDSは構築・削除に時間がかかる

EC2と比較して、RDSの作成には時間がかかった。

学習用途でも、作成・設定変更・削除に必要な時間と課金を意識する必要がある。

### パスワードとTerraform state

DBパスワードを変数で渡していても、通常の`password`属性を使うとTerraform stateに値が保存される。

そのため、tfvarsやstateをGitHubに公開しないことが重要。

本番環境ではSecrets Managerなどを使った認証情報の管理も検討する。

## 🏁 RESULT

**QUEST 015 CLEAR！**

- RDS PostgreSQLの構築
- Private EC2からRDSへの接続成功
- Session ManagerとVPCエンドポイントの利用
- テーブル作成・INSERT・SELECT成功
- バックアップ設定の変更と即時反映
- 設定変更後のデータ保持を確認
- Terraformによる21リソースの削除完了

RDSの構築から接続、データ操作、設定変更、削除までを一通り体験できた。