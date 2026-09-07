#!/usr/bin/env bash
# Issue を作成する。
#   引数なし: テンプレート(agentic_task.yml)を指定してブラウザで作成
#   引数あり: そのまま gh issue create に渡す（CLI 完結）
#     例: commands/gh-issue-create.sh --title "..." --body "..." --label task
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token

if [ "$#" -eq 0 ]; then
  # コンテナ内からはブラウザを開けないため URL を表示するだけ。
  echo "引数なしの場合はブラウザでの作成になります（コンテナからは開けません）。" >&2
  echo "CLI で作る場合: --title と --body（または --body-file）を指定してください。" >&2
  gh_run issue create --web --template agentic_task.yml
else
  gh_run issue create "$@"
fi
