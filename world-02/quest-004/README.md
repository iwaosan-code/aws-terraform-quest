# QUEST 004：S3の宝箱を開け

## 🎯 やったこと
- TerraformでS3 Bucketを作成
- Public Access Blockを設定
- Versioningを有効化
- SSE-S3（AES256）を設定
- Ownership Controlsを設定
- aws_s3_objectでtest.txtを配置
- AWSコンソールで設定とオブジェクトを確認
- terraform destroyまで実施

## 🧩 構成

```text
S3 Bucket
├─ Public Access Block
├─ Versioning
├─ SSE-S3
├─ Ownership Controls
└─ test.txt
```

## 💡 学んだこと
- S3 Bucket名はグローバルで一意
- S3の各種設定はTerraformでは複数のresourceに分かれる
- aws_s3_objectを使ってローカルファイルをS3へ配置できる

## 💥 ハマり
- aws_s3_bucket_ownership_controlsのresource名をタイプミス
- Versioning resourceを重複定義
- sourceとcontentの指定を見直した

## 🏁 RESULT

CLEAR