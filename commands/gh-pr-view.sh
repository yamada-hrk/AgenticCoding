#!/usr/bin/env bash
# PR の詳細を表示する。番号省略時はカレントブランチの PR。
#   例: commands/gh-pr-view.sh 45 --comments
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token
gh_run pr view "$@"
