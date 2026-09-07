-- 初回起動時に実行される初期化 SQL。
-- サンプルとして簡単なテーブルを作成する。

CREATE TABLE IF NOT EXISTS items (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO items (name) VALUES ('sample-1'), ('sample-2');
