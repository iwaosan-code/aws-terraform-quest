# QUEST 005：Lambdaを召喚せよ

## 🎯 やったこと
- TerraformでPython Lambdaを作成
- archive_fileでPythonコードをZIP化
- Lambda用Execution Roleを作成
- AWSLambdaBasicExecutionRoleを付与
- コンソールから手動テスト実行
- CloudWatch Logsでprint出力を確認
- Pythonコード変更 → plan差分 → apply → 再実行
- terraform destroyまで実施

## 🧩 構成

Python Code
└─ archive_file（ZIP）
   └─ Lambda
      ├─ IAM Execution Role
      └─ CloudWatch Logs

## 💡 学んだこと
- Lambda単体を試すだけならVPCや外部トリガーは不要
- handlerは「Pythonファイル名.関数名」で指定する
- source_code_hashでコード変更をTerraformが検知できる
- print()の出力はCloudWatch Logsで確認できる
- Log Group内には複数のLog Streamが作られることがある

## 💥 ハマり
- archive_fileで単一ファイルを指定するときはsource_fileを使う
- Lambdaが自動生成したCloudWatch Log GroupはTerraform管理外
- そのためLambdaをdestroyしてもLog Groupは残った

## 🏁 RESULT

CLEAR