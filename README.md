# Goose

このガイドでは、Docker環境でGooseマイグレーションツールをMySQLと共に使用する方法を説明します。

## 環境の起動

1. Dockerコンテナを起動

```bash
docker-compose up -d
```

2. gooseコンテナに接続

```bash
docker-compose exec goose sh
```

3. MySQLへの接続確認（必要な場合）：

```bash
docker-compose exec mysql mysql -ugoose -pgoose testdb
```

## マイグレーションの基本コマンド

gooseコンテナ内で以下のコマンドを実行できます：

### マイグレーションの状態確認

```bash
goose status
```

### 新しいマイグレーションファイルの作成

```bash
# `YYYYMMDDHHMMSS_add_new_table.sql`という形式の空のマイグレーションファイルが作成される
goose create add_new_table sql
```


### マイグレーションの適用（アップ）

```bash
goose up
```

### 特定のバージョンまでマイグレーション

```bash
goose up-to VERSION
```

### マイグレーションの取り消し（ダウン）

```bash
goose down
```

### 全てのマイグレーションを適用

```bash
goose up-to-date
```

## サンプルマイグレーションファイルの構造

```sql
-- +goose Up
-- +goose StatementBegin
CREATE TABLE example (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE example;
-- +goose StatementEnd
```

## マイグレーション作成から実行まで

1. `goose create`で新しいSQLファイルを作成
2.  作成されたマイングレーションファイルに、マイグレーション内容を記述
3. `goose up`コマンドを実行してマイグレーションを適用

## 外部のDBサーバに対してマイグレーションを実行
- multiStatements: `+goose StatementBegin`などを利用する場合に必要

```shell
DB_USER=goose \
DB_PASSWORD=goose \
DB_HOST=localhost \
DB_PORT=3906 \
DB_NAME=testdb \
goose -dir migrations mysql "$DB_USER:$DB_PASSWORD@tcp($DB_HOST:$DB_PORT)/$DB_NAME?parseTime=true&loc=Asia%2FTokyo&multiStatements=True" up

# 認証が必要な場合
goose -dir migrations -certfile=/etc/ssl/certs/ca-certificates.crt mysql "$DB_USER:$DB_PASSWORD@tcp($DB_HOST:$DB_PORT)/$DB_NAME?parseTime=true&loc=Asia%2FTokyo&multiStatements=True" up
```

## 注意事項

- マイグレーションは一度適用すると、手動で削除しない限りバージョン管理されます。
- 運用環境では`goose down`の使用に注意してください（データが失われる可能性があります）。
- 複雑なマイグレーションでは、トランザクションの扱いに注意してください。
- MySQLではデータ型の違い（例：PostgreSQLの`SERIAL`ではなく`AUTO_INCREMENT`）に注意してください。
- MySQLのデフォルト値や制約の構文がPostgreSQLと異なる場合があります。

## MySQL固有の設定

- 接続文字列の形式：`username:password@tcp(host:port)/dbname`
- コンテナの環境変数：
  - `GOOSE_DRIVER=mysql`
  - `GOOSE_DBSTRING=goose:goose@tcp(mysql:3306)/testdb`

## Appendix
### 途中で失敗する場合ロールバックしたい
- 単一のクエリ -> ロールバックされる
- 複数のクエリ -> 成功したところまではそのままになる

以下のようなクエリを実行した場合、成功したテーブル作成の部分はロールバックされない
=> ファイルを分割する戦略をとったほうが良さそう

```sql
-- +goose Up
-- +goose StatementBegin

-- まず成功する処理：ユーザー設定テーブルを作成
CREATE TABLE user_settings (
    user_id INT PRIMARY KEY,
    theme VARCHAR(50) DEFAULT 'default',
    notifications_enabled BOOLEAN DEFAULT TRUE
);

-- わざと失敗させる処理：存在しないカラムを参照
INSERT INTO user_settings (user_id, theme)
SELECT id, non_existent_column
FROM users;

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS user_settings;
-- +goose StatementEnd
```

試したこと
- `BEGIN - COMMIT`, `START TRANSACTION - COMMIT`でトランザクションを発生させる -> 失敗
- `+goose NO TRANSACTION`をつけ、自分でトランザクションを発生させる -> 失敗
- goのマイグレーションを作成する -> カスタムバイナリ（マイグレーションを実行するためのコード）を自分で作成する必要がある