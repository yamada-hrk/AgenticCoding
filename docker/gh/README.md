# gh (GitHub CLI) コンテナ

ホストに `gh` を入れずに、Docker コンテナ経由で GitHub CLI を使うための構成。
**docker-compose の管理外**（単発 CLI 実行用）。

## ビルド

```bash
docker build -t base-agentic-coding-gh:latest -f docker/gh/Dockerfile docker/gh
# UID/GID を合わせる場合:
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) \
  -t base-agentic-coding-gh:latest -f docker/gh/Dockerfile docker/gh
```

## 認証

Personal Access Token を環境変数で渡す（`gh auth login` の対話は使わない）。

```bash
export GH_TOKEN=ghp_xxxxxxxx        # Linux/macOS
$env:GH_TOKEN = 'ghp_xxxxxxxx'      # PowerShell
```

必要スコープの目安: `repo`, `read:org`, （Actions を触るなら）`workflow`。

## 使い方

ラッパースクリプト経由で実行する（カレントの git リポジトリを自動でマウント）。

```bash
# Linux/macOS/Git Bash
bin/gh auth status
bin/gh pr list
bin/gh issue create --template agentic_task.yml

# PowerShell
bin\gh.ps1 pr list
```

エイリアス登録すると `gh ...` で使える:

```bash
alias gh="$(git rev-parse --show-toplevel)/bin/gh"                       # bash/zsh
```
```powershell
function gh { & "$PWD\bin\gh.ps1" @args }                                # PowerShell profile
```

## 仕組み / 注意

- リポジトリのトップを `/work` にマウントし、カレントの相対位置で実行する。
- `git push` を伴う操作（`gh pr create` 等）は、イメージ内の credential helper が
  `GH_TOKEN` を使って認証するため追加設定不要。
- 実行ユーザーは Linux/macOS では `id -u:id -g`、Windows では `.env` の `UID/GID`
  （既定 1000）。生成ファイルの所有者をホストに合わせる。
- `gh` の設定・キャッシュはコンテナ内 `/home/gh`（毎回破棄）。ホストに残さない。
- `GH_IMAGE` 環境変数でイメージ名を上書き可能。
