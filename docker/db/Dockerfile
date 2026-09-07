# db 用イメージ: PostgreSQL 16 をベースに初期化 SQL を同梱する。
# /docker-entrypoint-initdb.d/ 内のスクリプトは初回起動時に自動実行される。
FROM postgres:16-alpine

# ロケール等の既定値。実際の認証情報は compose の環境変数で上書きする。
ENV POSTGRES_DB=app \
    POSTGRES_USER=app \
    LANG=en_US.utf8

# 初期化スクリプトを配置。
COPY docker/db/init/ /docker-entrypoint-initdb.d/
