# QUEST 003：Load Balancer

## 🎯 やったこと
- ALBをPublic Subnetに配置
- EC2をPrivate Subnetに配置
- ALB → EC2の通信をSecurity Groupで制御
- HTTP Listener / Target Group / Health Checkを構成
- ALBのDNS名からApacheのページを表示
- EC2をreplaceしてuser_dataの変更を反映
- terraform destroyまで実施

## 🧩 構成

Internet
└─ ALB（Public Subnets）
   └─ EC2（Private Subnet）

## 💡 学んだこと
- Internet-facing ALBでは複数AZのSubnetを指定する
- EC2のSGはALBのSGからのみ通信を許可できる
- user_dataを変更しても既存EC2上でそのまま再実行されるわけではない
- terraform plan -replace / applyでEC2を再作成できる

## 💥 ハマり
- user_dataを変更してapplyしてもWebページの表示が変わらなかった
- EC2をreplaceして初めて変更後のuser_dataが実行された

## 🏁 RESULT

CLEAR