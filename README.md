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
```shell
DB_USER=goose \
DB_PASSWORD=goose \
DB_HOST=localhost \
DB_PORT=3906 \
DB_NAME=testdb \
goose -dir migrations mysql "$DB_USER:$DB_PASSWORD@tcp($DB_HOST:$DB_PORT)/$DB_NAME?parseTime=true&loc=Asia%2FTokyo&multiStatements=True" up
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