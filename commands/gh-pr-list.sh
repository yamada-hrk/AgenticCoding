#!/usr/bin/env bash
# PR 一覧を表示する。
#   例: commands/gh-pr-list.sh --state open --limit 20
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

require_token
gh_run pr list "$@"
