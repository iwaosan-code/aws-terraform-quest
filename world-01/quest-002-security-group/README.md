# QUEST 002：Security Group

## 🎯 やったこと
- Public / Private / ALB用Security GroupをTerraformで作成
- ingress / egressルールを設定
- Security Group同士を参照するルールを確認
- AWSコンソールで確認
- terraform destroyまで実施

## 🧩 構成

```text
Security Groups
├─ Public SG
├─ Private SG
└─ ALB SG
```

## 💡 学んだこと
- Security Groupはリソースに適用するステートフルなFirewall
- CIDRだけでなく、別のSecurity Groupを通信元として指定できる
- 「どこから、何の通信を許可するか」を考えてルールを作る

## 💥 ハマり
- ALB SGをPrivate SGから参照していたため、依存関係によって削除待ちになる場面を経験
- tfvarsの値不足でplan時に入力を求められた

## 🏁 RESULT

CLEAR