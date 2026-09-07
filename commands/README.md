# commands/

`gh`（GitHub CLI）をコンテナ経由で実行するスクリプト群。
`bin/gh` ラッパーを呼ぶだけの薄い層で、`Makefile` のターゲットから使う。

## 前提

- `bash`（Windows は Git Bash）と `make`
- gh イメージをビルド済み: `make gh-build`
- トークン: `export GH_TOKEN=ghp_xxxx`（`GITHUB_TOKEN` も可）

## Makefile 経由（推奨）

```bash
make                 # ヘルプ
make gh-build        # イメージビルド
make gh-auth         # 認証確認
make issues          ARGS="--state open --limit 5"
make issue           ARGS='--title "DB接続を追加" --body "..." --label task'
make issue-view      ARGS="123 --comments"
make prs
make pr              ARGS='--base main'          # 引数なしなら --fill
make pr-view         ARGS=45
make pr-checkout     ARGS=45
make gh              ARGS="api /repos/{owner}/{repo}"   # 任意の gh コマンド
```

追加オプションはすべて `ARGS="..."` で渡し、そのまま `gh` に転送される。

## スクリプト単体で実行

```bash
commands/gh-issue-list.sh --label task
commands/gh.sh release list
```

## 一覧

| スクリプト | 対応 make | 内容 |
|-----------|-----------|------|
| `gh-auth.sh`        | `gh-auth`     | `gh auth status` |
| `gh-issue-list.sh`  | `issues`      | `gh issue list` |
| `gh-issue-create.sh`| `issue`       | `gh issue create`（引数なしは --web + テンプレート） |
| `gh-issue-view.sh`  | `issue-view`  | `gh issue view <番号>` |
| `gh-pr-list.sh`     | `prs`         | `gh pr list` |
| `gh-pr-create.sh`   | `pr`          | `gh pr create`（引数なしは --fill） |
| `gh-pr-view.sh`     | `pr-view`     | `gh pr view` |
| `gh-pr-checkout.sh` | `pr-checkout` | `gh pr checkout <番号>` |
| `gh.sh`             | `gh`          | 任意の `gh` サブコマンド |
| `_common.sh`        | -             | 共通処理（source 用） |
