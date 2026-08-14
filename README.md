# 🎮 AWS QUEST

AWSを浅く広く実際に触りながら、
Terraform・GitHub・AIを使ってAWSのサービスと構成を理解するための学習プロジェクト。

## 🎯 Goal

AIにTerraformコードを生成させること自体を目的とせず、

- AWSサービスの役割を理解する
- サービス同士のつながりを理解する
- Terraformコードを読んで何をしているか説明できる
- AIが生成したコードをレビューできる
- 要件から利用するAWSサービスを選択できる

ことを最終目標とする。

## 🗺️ World Map

| World | Theme | Status |
|---|---|---|
| WORLD 1 | Network / EC2 / ALB | 🚶 |
| WORLD 2 | Serverless | 🔒 |
| WORLD 3 | Database | 🔒 |
| WORLD 4 | API / Integration | 🔒 |
| WORLD 5 | Security | 🔒 |
| WORLD 6 | Container | 🔒 |
| WORLD 7 | Monitoring | 🔒 |

## ⚔️ Game System

- **QUEST**：TerraformでAWS環境を構築する
- **AWS図鑑**：実際に触ったAWSサービスを記録する
- **連携技**：複数のAWSサービスを組み合わせる
- **MIMIC**：AI生成コードに潜む問題をレビューする
- **BOSS**：要件から自分でAWS構成を設計する

## 🧭 Basic Flow

QUEST
↓
Terraformコードを読む
↓
terraform plan
↓
terraform apply
↓
AWS Management Consoleで確認
↓
動作確認
↓
terraform destroy
↓
GitHubへ記録
↓
CLEAR 🎉

## 📂 Repository

```text
aws-terraform-quest/
├── 00-rules/
├── world-01/
├── world-02/
├── ...
├── .gitignore
└── README.md