# GitHub Actions ワークフロー

Issue コメントを契機に OpenSpec / OpenWiki を実行し、結果を PR にする。

| ワークフロー | 契機 | 動作 | Secret |
|---|---|---|---|
| `openspec-archive.yml` | Issue コメント `/openspec archive <change-id>` | `documents/openspec/` で `openspec archive <id> --yes` → PR | 不要 |
| `openwiki-update.yml` | Issue コメント `/openwiki` | `documents/openwiki/` で `openwiki code --update` → PR | `GEMINI_API_KEY` |

`workflow_dispatch`（手動実行）にも対応。OpenSpec は `change_id` 入力が必要。

## 事前準備

### 1. リポジトリ設定

- **Settings → Actions → General → Workflow permissions**
  - "Read and write permissions" を有効化
  - "Allow GitHub Actions to create and approve pull requests" にチェック
    （`peter-evans/create-pull-request` が GITHUB_TOKEN で PR を作るため）

### 2. Secret 登録（OpenWiki 用）

- **Settings → Secrets and variables → Actions → New repository secret**
  - `GEMINI_API_KEY` … Google AI Studio (aistudio.google.com) で発行
- ローカルの `.env` は Actions からは参照されない。

### 3. ディレクトリ初期化

- **OpenSpec**: ローカルで一度だけ
  ```bash
  cd documents && npx -y @fission-ai/openspec@latest init
  ```
  して `documents/openspec/` をコミット。以降 `/opsx:propose` 等で change を作る。
- **OpenWiki**: 初回の `/openwiki` 実行が `documents/openwiki/` をブートストラップする。

## セキュリティ / 挙動メモ

- `issue_comment` ワークフローは常にデフォルトブランチのファイルで実行される。
- 実行できるのは `author_association` が OWNER / MEMBER / COLLABORATOR のユーザーのみ。
- PR は対象 Issue（PR へのコメントは対象外）でのみ作成。
- GITHUB_TOKEN が作った PR は他ワークフローを再発火しない（ループ防止）。
- OpenWiki は `documents/openwiki` のみコミット対象。副次生成される
  `AGENTS.md` / `CLAUDE.md` 等はランナー上で破棄される。
- 無料枠の Gemini で 429（レート制限）が出る場合は `OPENWIKI_MODEL_ID` を
  `gemini-2.5-flash` のまま実行間隔を空けるか、課金枠へ。
