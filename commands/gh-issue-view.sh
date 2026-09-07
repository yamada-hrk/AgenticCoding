#!/usr/bin/env bash
# Issue の詳細を表示する。
#   例: commands/gh-issue-view.sh 123
#       commands/gh-issue-view.sh 123 --comments
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

if [ "$#" -eq 0 ]; then
  echo "使い方: gh-issue-view.sh <issue番号> [gh のオプション]" >&2
  exit 2
fi

require_token
gh_run issue view "$@"
