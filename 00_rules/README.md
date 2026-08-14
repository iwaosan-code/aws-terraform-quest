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

AWS QUESTで作業した内容をGitHubへ保存する基本手順。

### 1. 変更内容を確認

```powershell
git status
```

意図したファイルだけが変更されていることを確認する。

### 2. セーブ対象をステージング

```powershell
git add .
```

`.` は現在のフォルダ以下の変更をステージングするという意味。

### 3. ステージング内容を確認

```powershell
git status
```

`Changes to be committed` に、意図したファイルだけが含まれていることを確認する。

### 4. ローカルGitへセーブ

```powershell
git commit -m "変更内容を表すメッセージ"
```

例：

```powershell
git commit -m "Complete quest 001 network"
```

### 5. GitHubへセーブ

```powershell
git push
```

初回のみ、GitHubとの追跡関係を設定するため以下を使用する。

```powershell
git push -u origin main
```

2回目以降は `git push` だけでOK。

---

## 🔄 基本ループ

```text
ファイルを編集
    ↓
git status
    ↓
git add .
    ↓
git status
    ↓
git commit -m "変更内容"
    ↓
git push
    ↓
GitHubへセーブ完了 🎉
```

---

## ⚠️ セーブ前チェック

`git add .` や `git commit` を実行する前に以下を確認する。

- `terraform.tfvars` が含まれていないか
- `*.tfstate` が含まれていないか
- AWS Access Key / Secret Access Key が含まれていないか
- パスワードやその他の秘密情報が含まれていないか
- 意図していないファイルまでステージングしていないか

---

## ↩️ 直前の変更を取り消したい場合

まず履歴を確認する。

```powershell
git log --oneline -5
```

GitHubへpush済みのコミットを安全に取り消す場合：

```powershell
git revert <コミットID>
```

取り消した内容をGitHubへ反映：

```powershell
git push
```

履歴自体は削除せず、「変更を取り消した」という新しいコミットが作成される。