#!/usr/bin/env bash
# commands/ 配下スクリプトの共通処理。各スクリプトから source して使う。
set -euo pipefail

# Git Bash (Windows) のパス自動変換を無効化。
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

# リポジトリルートと gh ラッパーのパス。
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
GH="${REPO_ROOT}/bin/gh"

# GITHUB_TOKEN も受け付ける。
: "${GH_TOKEN:=${GITHUB_TOKEN:-}}"
export GH_TOKEN

# 認証必須の操作の前に呼ぶ。
require_token() {
  if [ -z "${GH_TOKEN}" ]; then
    echo "エラー: GH_TOKEN(または GITHUB_TOKEN) を設定してください。" >&2
    echo "  例: export GH_TOKEN=ghp_xxxxxxxx" >&2
    exit 1
  fi
}

# gh をコンテナ経由で実行。
gh_run() {
  "${GH}" "$@"
}
