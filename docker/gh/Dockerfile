# gh (GitHub CLI) をホストに入れずコンテナ経由で使うためのイメージ。
# docker-compose の管理外。単発 CLI 実行用。
#   ビルド:  docker build -t base-agentic-coding-gh:latest -f docker/gh/Dockerfile docker/gh
#   実行:    bin/gh または bin/gh.ps1 のラッパー経由
FROM alpine:3.20

# ホストの UID/GID をビルド時に合わせられるようにする（実行時は -u で上書き可）。
ARG UID=10001
ARG GID=10001

RUN apk add --no-cache github-cli git openssh-client ca-certificates less \
    && if ! getent group "${GID}" >/dev/null; then addgroup -g "${GID}" gh; fi \
    && if ! getent passwd "${UID}" >/dev/null; then \
         adduser -D -u "${UID}" -G "$(getent group "${GID}" | cut -d: -f1)" gh; \
       fi \
    # 任意 UID で実行してもホームに書き込めるようにする（gh の設定キャッシュ用）。
    && mkdir -p /home/gh && chmod 1777 /home/gh \
    # マウントした作業ディレクトリを git が信頼するようにする。
    && git config --system --add safe.directory '*' \
    # gh auth setup-git 相当: GH_TOKEN を使って push/clone の認証を通す。
    && git config --system --add credential.https://github.com.helper '' \
    && git config --system --add credential.https://github.com.helper '!gh auth git-credential' \
    && git config --system --add credential.https://gist.github.com.helper '' \
    && git config --system --add credential.https://gist.github.com.helper '!gh auth git-credential'

ENV HOME=/home/gh \
    GH_PROMPT_DISABLED=1

USER ${UID}:${GID}
WORKDIR /work

ENTRYPOINT ["gh"]
CMD ["--help"]
