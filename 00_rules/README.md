# AWS QUEST - Terraform Rules

## Common Variables

| Variable | Purpose |
|---|---|
| `project_name` | プロジェクト名を表す共通変数 |
| `environment` | 環境名を表す共通変数 |
| `aws_region` | AWSリージョンを表す共通変数 |

## Naming Rule

リソース名は原則として以下。

`${project_name}-${environment}-${resource}`

例：
`aws-quest-dev-vpc`

## Common Tags

- `Project` = `var.project_name`
- `Environment` = `var.environment`
- `ManagedBy` = `Terraform`

## 💾 Git セーブ手順

### 1. 変更内容を確認
意図しないファイルが含まれていないことを確認する

```powershell
`git status`

### 2. セーブ対象をステージング
```powershell
`git add .`

### 3. ステージングされた内容を確認
```powershell
`git status`
`Changes to be committed` の内容を確認する。

### 4. ローカルGitへセーブ
`git commit -m` "変更内容を表すメッセージ"

例：
`git commit -m` "Complete quest 001 network"

###5. GitHubへセーブ
`git push`

初回のみ：
`git push -u origin main`

以降は `git push` だけでOK

⚠️ セーブ前チェック
- terraform.tfvars が含まれていないか
- *.tfstate が含まれていないか
- AWS Access Key / Secret Access Key が含まれていないか
- パスワードやその他の秘密情報が含まれていないか
- 意図していないファイルまで `git add .` していないか