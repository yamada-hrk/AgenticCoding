#!/usr/bin/env bash
# Issue 一覧を表示する。追加オプションはそのまま gh に渡す。
#   例: commands/gh-issue-list.sh --state open --limit 20 --label task
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token
gh_run issue list "$@"
