# AgenticCoding

Agentic Coding のベース環境。Go アプリ + PostgreSQL の Docker 構成に、
GitHub Issue のコメントで駆動する OpenSpec / OpenWiki のワークフローを組み合わせている。

## Issue コメントのトリガー

対象 Issue（PR ではない）にコメントすると対応するワークフローが起動する。
起動条件は **「コメント実行者」と「Issue 起票者」の両方が admin 権限**であること。
どちらかが欠けると「管理者のみ」と返信して何もしない。

> 非 admin が立てた Issue は動かせない。外部の要望は admin が内容を確認し、
> **admin 自身が新規 Issue として起票し直す**（＝プロンプトインジェクション対策。
> 本文が信頼できる人の手を経ることを保証する）。

| コメント | 起動するワークフロー | 動作 | 必要 Secret |
|---|---|---|---|
| `/opsx:propose [補足]` | **OpenSpec Propose** | Issue の内容を依頼として、Claude Code が変更提案（proposal / specs 差分 / design / tasks）を `documents/openspec/` に作成し PR。コメントに続けた文があれば補足指示として扱う | `CLAUDE_CODE_OAUTH_TOKEN` |
| `/opsx:apply [<change-id>]` | **OpenSpec Apply** | Claude Code が対象 change の `tasks.md` に沿って `src/` 等を実装し PR（archive はしない） | `CLAUDE_CODE_OAUTH_TOKEN` |
| `/openspec` | **OpenSpec Archive** | Issue 内容から対象 change を自動判定して `archive`（本仕様へ反映）し PR | 不要（判定不能時のみ `GEMINI_API_KEY`） |
| `/openspec archive <id> [<id> ...]` | **OpenSpec Archive** | 指定した change-id を順に `archive` し PR | 不要 |
| `/openwiki` | **OpenWiki Update** | コードから Wiki を再生成して `documents/openwiki/` に出力し PR | `GEMINI_API_KEY` |

- いずれもコメントに 👀 を付けてから実行し、結果を Issue にコメント返信する。
- 生成物は必ず PR。直接 main には push しない。PR は `CI` ワークフロー（`go build` / `vet` / `test` / `gofmt`）で検証される。
- 手動実行: Actions タブから `OpenSpec Archive` / `OpenWiki Update` を `workflow_dispatch` でも起動可。
- `/opsx:apply` の change-id は、コメント明示 → Issue 本文との一致（1件のみ）→ 未アーカイブが1件のみ、の順で決定。特定できなければ候補を返して停止（推測はしない）。

### `/openspec` の change-id 自動判定（上から順に）

1. コメントで明示（`/openspec archive add-auth fix-login`、複数可）
2. Issue のタイトル/本文に含まれる実在の change-id（1〜複数ヒットで採用）
3. 未アーカイブの change が1件だけ → それを採用
4. 判定不能 → 候補一覧 ＋ Gemini の推測をコメント（archive はせず、人が 1 の形式で再指定）

詳細は [.github/workflows/README.md](.github/workflows/README.md)。

## セットアップ

### リポジトリ設定

- **Settings → Actions → General → Workflow permissions**
  - "Read and write permissions" を有効化
  - "Allow GitHub Actions to create and approve pull requests" にチェック

### Secret 登録（Settings → Secrets and variables → Actions）

| Secret | 取得元 | 用途 |
|---|---|---|
| `GEMINI_API_KEY` | Google AI Studio (aistudio.google.com) | OpenWiki 生成 / OpenSpec の change 推測 |
| `CLAUDE_CODE_OAUTH_TOKEN` | ローカルで `claude setup-token`（Claude Pro/Max） | OpenSpec Propose |

ローカルの `.env` は Actions からは参照されない。

## リポジトリ構成

```
src/                  Go 1.23 アプリ（標準ライブラリのみ、/healthz・/db エンドポイント）
docker/
  app/                アプリイメージ（マルチステージ、非root、UID/GID 指定可）
  db/                 PostgreSQL 16 + 初期化 SQL
  gh/                 GitHub CLI をコンテナ実行するためのイメージ
docker-compose.yml    app + db（UID/GID・DB データの bind mount）
bin/gh, bin/gh.ps1    gh コンテナのラッパー（bash / PowerShell）
commands/             gh 操作スクリプト（Makefile から呼ぶ）
Makefile              gh 操作のショートカット（make help）
documents/
  openspec/           OpenSpec（変更提案 → 仕様）。.claude/ に opsx コマンド
  openwiki/           OpenWiki 生成物（初回 /openwiki で作成）
  issue-template.md   ローカル issues/ 運用向けの雛形
.github/
  ISSUE_TEMPLATE/     GitHub Issue Forms（Agentic Coding タスク）
  workflows/          OpenSpec(propose/apply/archive) / OpenWiki / CI ワークフロー
```

## ローカル開発

### アプリ + DB

```bash
cp .env.example .env          # POSTGRES_PASSWORD 等を編集
docker compose up -d
curl localhost:8080/healthz   # ok
curl localhost:8080/db        # db reachable
docker compose down           # 停止（データは ./data/db に残る）
```

Linux では `.env` の `UID` / `GID` を `id -u` / `id -g` の値にするとマウント先の権限がホストに揃う。

### gh（GitHub CLI）

ホストに入れず、コンテナ経由で使う。

```bash
docker build -t base-agentic-coding-gh:latest -f docker/gh/Dockerfile docker/gh
export GH_TOKEN=ghp_xxxx        # or .env に記載

make                           # コマンド一覧
make issues  ARGS="--state open"
make issue   ARGS='--title "x" --body "y" --label task'
make gh      ARGS="api /repos/{owner}/{repo}"
```

詳細は [commands/README.md](commands/README.md) / [docker/gh/README.md](docker/gh/README.md)。

### OpenSpec（ローカル）

`documents/` をカレントにして使う（OpenSpec の実体が `documents/openspec/` にあるため）。

```bash
cd documents
npx -y @fission-ai/openspec@latest list      # 変更提案の一覧
npx -y @fission-ai/openspec@latest validate --all --strict
```

Claude Code なら `documents/` で `/opsx:propose` `/opsx:apply` `/opsx:archive` が使える。

## ワークフローの流れ

```
Issue 起票（内容が依頼になる）
  └─ /opsx:propose               → 提案 PR（documents/openspec/changes/<id>/）
       └─ レビュー・マージ
            └─ /opsx:apply（or ローカルで実装）  → 実装 PR（src/ ＋ tasks.md）
                 │                                    └─ CI（build/vet/test/gofmt）→ レビュー・マージ
                 └─ /openspec                       → archive PR（specs/ へ反映）
Issue コメント /openwiki                              → Wiki 更新 PR（随時）
```

`/opsx:apply` はコードを自律生成するためリスクが高い。CI と PR レビューを必ず通すこと。
使用量は Claude サブスク（Pro/Max）枠を消費する。
