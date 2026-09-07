# app 用イメージ: Go のマルチステージビルド。
# ビルドステージで静的バイナリを作り、実行ステージは最小構成にする。

# ---- ビルドステージ ----
FROM golang:1.23-alpine AS build

WORKDIR /src

# 依存解決を先に行いレイヤーキャッシュを効かせる。
COPY src/go.mod ./
# go.sum があればコピー（現状は依存なしのため任意）。
COPY src/go.su[m] ./
RUN go mod download

# ソースをコピーしてビルド。
COPY src/ ./
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/app .

# ---- 実行ステージ ----
FROM alpine:3.20

# ホスト側の UID/GID を .env 経由（compose の build args）で受け取る。
# マウントしたディレクトリの権限がホストのユーザーと一致するようにする。
ARG UID=10001
ARG GID=10001

RUN apk add --no-cache ca-certificates \
    && if ! getent group "${GID}" >/dev/null; then addgroup -g "${GID}" appgroup; fi \
    && if ! getent passwd "${UID}" >/dev/null; then \
         adduser -D -u "${UID}" -G "$(getent group "${GID}" | cut -d: -f1)" appuser; \
       fi

COPY --from=build /out/app /usr/local/bin/app

# 数値指定にしておくと compose の user: 上書きと矛盾しない。
USER ${UID}:${GID}
EXPOSE 8080

ENV APP_PORT=8080 \
    DB_HOST=db \
    DB_PORT=5432

# 簡易ヘルスチェック。
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -qO- http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/usr/local/bin/app"]
