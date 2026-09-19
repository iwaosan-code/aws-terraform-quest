# QUEST 001：Network

## 🎯 やったこと
- TerraformでVPCを作成
- Public / Private Subnetを2AZ（ap-northeast-1a / 1c）に作成
- Internet Gatewayを作成
- Public / Private Route Tableを作成・関連付け
- AWSコンソールで構成を確認
- terraform destroyまで実施

## 🧩 構成

```text
VPC
├─ Public Subnet（1a / 1c）
├─ Private Subnet（1a / 1c）
├─ Internet Gateway
└─ Route Table（Public / Private）
```

## 💡 学んだこと
- Subnetはネットワーク上の「入れ物」で、Public / Privateはルーティングによって決まる
- Route TableとSubnetの関連付けまで含めてネットワーク構成になる
- Terraformで「構築 → 確認 → destroy」する基本サイクルを経験

## 🏁 RESULT

CLEAR