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