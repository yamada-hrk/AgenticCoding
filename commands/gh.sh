#!/usr/bin/env bash
# 任意の gh サブコマンドをコンテナ経由で実行する汎用エントリ。
#   例: commands/gh.sh release list
#       commands/gh.sh api /repos/{owner}/{repo}
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token
gh_run "$@"
