#!/usr/bin/env bash
# 指定した PR をローカルにチェックアウトする。
#   例: commands/gh-pr-checkout.sh 45
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=commands/_common.sh
. "${SCRIPT_DIR}/_common.sh"

if [ "$#" -eq 0 ]; then
  echo "使い方: gh-pr-checkout.sh <PR番号|URL|ブランチ名>" >&2
  exit 2
fi

require_token
gh_run pr checkout "$@"
