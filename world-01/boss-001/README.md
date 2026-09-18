# BOSS 001：Web構成を組み上げる

## 🎯 やったこと
- 要件からAWS構成を自分で設計
- ALBをPublic Subnet、EC2をPrivate Subnetへ配置
- NAT Gateway + EIPでPrivate EC2のアウトバウンド経路を構成
- Session Manager用IAM Roleを設定
- Apacheをuser_dataで導入
- Web表示とAWSリソースを確認
- terraform destroyまで実施

## 🧩 構成

Internet
└─ ALB（Public Subnet 1a / 1c）
   └─ EC2（Private Subnet 1a）
      └─ NAT Gateway + EIP（Outbound）

Management
└─ Systems Manager Session Manager
   └─ IAM Role → EC2

## 💡 学んだこと
- ハンズオンでは可用性とコストのバランスを考える
- NAT GatewayはPublic Subnetに配置してEIPを関連付ける
- depends_onは通信経路ではなくTerraformのリソース依存関係を表す
- IAM Trust PolicyとRoleに付与する権限は役割が違う
- ALBでは複数AZのSubnetが必要

## 💥 ハマり
- Route Tableとの関連付けを見直した
- ALBとの関連付けを見直した
- NAT Gatewayはdestroy後もしばらくDeleted状態で一覧に残ることを確認

## 🏁 RESULT

CLEAR