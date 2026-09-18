# MIMIC 001：Find the Difference

## 🎯 やったこと
- AI生成を想定したTerraformコードをレビュー
- 動くかどうかだけでなく、要件・セキュリティ・保守性の観点から問題を探した

## 🔍 主なレビュー観点
- EC2の選択条件が広すぎて意図しない対象を拾わないか
- EC2をPrivate Subnetへ配置すべきではないか
- SSHではなくSession Managerを利用できないか
- EC2 SGのingressをALB SGからのみにできないか
- SSHを許可する場合、接続元CIDRが限定されているか
- 必要なPrivate Subnetなどが不足していないか
- locals / variablesなどへ分割した方が保守しやすくないか

## 💡 学んだこと
- Terraformレビューでは文法だけでなく「要件に対してこの構成でよいか」を見る
- セキュリティや運用まで含めてコードを見る
- 存在しない問題を無理に探す必要はない
- AIが書いたコードでも最終判断は人間が行う

## 🏁 RESULT

CLEAR