# GitHub Actions ワークフロー

Issue コメントを契機に OpenSpec / OpenWiki を実行し、結果を PR にする。

| ワークフロー | 契機 | 動作 | Secret |
|---|---|---|---|
| `openspec-propose.yml` | Issue コメント `/opsx:propose <アイデア>` | Claude Code が `documents/openspec/` に変更提案を作成 → PR | `CLAUDE_CODE_OAUTH_TOKEN` |
| `openspec-apply.yml` | Issue コメント `/opsx:apply [<change-id>]` | Claude Code が対象 change の `tasks.md` に沿って `src/` 等を実装 → PR（archive しない） | `CLAUDE_CODE_OAUTH_TOKEN` |
| `openspec-archive.yml` | Issue コメント `/openspec [archive] [<change-id> ...]` | `documents/openspec/` で `openspec archive <id> --yes`（複数可）→ PR | `GEMINI_API_KEY`（判定不能時のみ） |
| `openwiki-update.yml` | Issue コメント `/openwiki` | `documents/openwiki/` で `openwiki code --update` → PR | `GEMINI_API_KEY` |
| `ci.yml` | `src/**` を含む push / PR | `gofmt` / `go vet` / `go build` / `go test`（`src/` で実行） | 不要 |

`openspec-archive` と `openwiki-update` は `workflow_dispatch`（手動実行）にも対応。
archive は `change_ids` 入力（空白/カンマ区切りで複数可）が必要。

### OpenSpec Propose / Apply の仕組み

- Claude Code（`anthropics/claude-code-action`）を CI で実行し、`documents/.claude/skills/` の
  スキル（`openspec-propose` / `openspec-apply-change`）の手順に従わせる。
- OpenSpec の実体は `documents/openspec/` にあるため、プロンプトで「`openspec` コマンドは
  `documents/` をカレントにして実行」と指示している。実装ファイルの編集はリポジトリルート
  （`src/` など）に対して行う。
- 認証は Claude サブスク（Pro/Max）の OAuth トークン。使用量はサブスク枠を消費。
- 曖昧さ・仕様との矛盾があれば、成果物を作らず Issue にコメントして停止する。

**Propose**（`/opsx:propose`）
- 依頼テキストから change を作り、proposal / specs 差分 / design / tasks を生成。
- **計画のみ**。実装・apply・archive は行わない。

**Apply**（`/opsx:apply [<change-id>]`）
- 対象 change の `tasks.md` を実装し、チェックを更新。`src/` 等を編集。
- **archive は禁止**。`--max-turns 100`。`go build` / `go vet` が通ることを確認させる。
- change-id 判定: コメント明示 → Issue 本文と一致（1件のみ）→ 未アーカイブが1件のみ、の順。
  特定できなければ候補を返して停止（**推測はしない**。archive と違い実装は高コストなため）。
- コードは自律生成されるため **CI（`ci.yml`）と PR レビューを必ず通す**こと。

### OpenSpec の change-id 判定

`/openspec` コメント時、対象 change-id を次の順で決める:

1. コメントで明示（`/openspec archive add-auth fix-login` など、複数可）
2. Issue のタイトル/本文に含まれる実在の change-id（1〜複数ヒットで採用）
3. 未アーカイブの change が1件だけ → それを採用
4. 判定不能 → 候補一覧 ＋ **Gemini の推測**をコメント（archive はしない。人が 1 の形式で再指定）

複数対象は順に archive し、成功/失敗を PR 本文と返信コメントに記載。1件なら
ブランチ `openspec/archive-<id>`、複数なら `openspec/archive-issue-<番号>`。

## 事前準備

### 1. リポジトリ設定

- **Settings → Actions → General → Workflow permissions**
  - "Read and write permissions" を有効化
  - "Allow GitHub Actions to create and approve pull requests" にチェック
    （`peter-evans/create-pull-request` が GITHUB_TOKEN で PR を作るため）

### 2. Secret 登録

- **Settings → Secrets and variables → Actions → New repository secret**
  - `GEMINI_API_KEY` … Google AI Studio (aistudio.google.com) で発行（OpenWiki / OpenSpec archive）
  - `CLAUDE_CODE_OAUTH_TOKEN` … ローカルで `claude setup-token`（Pro/Max）→ 出力を登録（OpenSpec propose / apply）
- ローカルの `.env` は Actions からは参照されない。

### 3. ディレクトリ初期化

- **OpenSpec**: 初期化済み（`documents/openspec/` + `documents/.claude/`）。
  再初期化する場合は `cd documents && npx -y @fission-ai/openspec@latest init --tools claude`。
  ローカルで `/opsx:*` を使うときも `documents/` をカレントにすること。
- **OpenWiki**: 初回の `/openwiki` 実行が `documents/openwiki/` をブートストラップする。

## セキュリティ / 挙動メモ

- `issue_comment` ワークフローは常にデフォルトブランチのファイルで実行される。
- 各ワークフローは先頭に `gate` ジョブを持ち、`GET /repos/{}/collaborators/{}/permission`
  で実行者の権限を確認。**admin 以外は本処理をスキップ**し、Issue に「管理者のみ」と
  返信して正常終了する（Actions は緑のまま・失敗通知なし）。
- PR は対象 Issue（PR へのコメントは対象外）でのみ作成。
- GITHUB_TOKEN が作った PR は他ワークフローを再発火しない（ループ防止）。
- OpenWiki は `documents/openwiki` のみコミット対象。副次生成される
  `AGENTS.md` / `CLAUDE.md` 等はランナー上で破棄される。
- 無料枠の Gemini で 429（レート制限）が出る場合は `OPENWIKI_MODEL_ID` を
  `gemini-2.5-flash` のまま実行間隔を空けるか、課金枠へ。
