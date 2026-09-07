#!/usr/bin/env bash
# PR を作成する。
#   引数なし: --fill（コミットからタイトル/本文を補完）
#   引数あり: そのまま gh pr create に渡す
#     例: commands/gh-pr-create.sh --base main --title "..." --body "..."
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token

if [ "$#" -eq 0 ]; then
  gh_run pr create --fill
else
  gh_run pr create "$@"
fi
