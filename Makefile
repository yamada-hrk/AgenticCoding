# GitHub CLI(gh) をコンテナ経由で叩くためのショートカット。
# 実行には bash（Windows は Git Bash）と make が必要。
# 追加引数は ARGS="..." で渡す。
#   例: make issues ARGS="--state open --limit 5"
#       make issue  ARGS='--title "DB接続を追加" --body "..." --label task'
#       make gh     ARGS="release list"

SHELL := bash
CMD   := commands
IMAGE ?= base-agentic-coding-gh:latest

.DEFAULT_GOAL := help

.PHONY: help gh-build gh-auth issues issue issue-view prs pr pr-view pr-checkout gh

help: ## コマンド一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
	 | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2}'

gh-build: ## gh コンテナイメージをビルド
	docker build -t $(IMAGE) -f docker/gh/Dockerfile docker/gh

gh-auth: ## 認証状態を確認
	@bash $(CMD)/gh-auth.sh $(ARGS)

issues: ## Issue 一覧
	@bash $(CMD)/gh-issue-list.sh $(ARGS)

issue: ## Issue 作成（例: make issue ARGS='--title "x" --body "y" --label task'）
	@bash $(CMD)/gh-issue-create.sh $(ARGS)

issue-view: ## Issue 詳細（例: make issue-view ARGS=123）
	@bash $(CMD)/gh-issue-view.sh $(ARGS)

prs: ## PR 一覧
	@bash $(CMD)/gh-pr-list.sh $(ARGS)

pr: ## PR 作成（引数なしで --fill / 例: make pr ARGS='--base main'）
	@bash $(CMD)/gh-pr-create.sh $(ARGS)

pr-view: ## PR 詳細（例: make pr-view ARGS=45）
	@bash $(CMD)/gh-pr-view.sh $(ARGS)

pr-checkout: ## PR をチェックアウト（例: make pr-checkout ARGS=45）
	@bash $(CMD)/gh-pr-checkout.sh $(ARGS)

gh: ## 任意の gh コマンド（例: make gh ARGS="api /repos/{owner}/{repo}"）
	@bash $(CMD)/gh.sh $(ARGS)
