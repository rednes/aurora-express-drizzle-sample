# aurora-express-drizzle-sample

Aurora PostgreSQL Serverless Express に Drizzle ORM で接続するサンプルコードです。

## 前提条件

以下のツールがインストール・設定済みであることを確認してください。

| ツール | バージョン | 用途 |
|--------|-----------|------|
| [Node.js](https://nodejs.org/) | v18 以上 | アプリケーションの実行 |
| [AWS CLI](https://aws.amazon.com/jp/cli/) | v2 | IAM 認証トークンの生成 |
| AWS 認証情報 | - | Aurora への IAM 認証に使用（`aws configure` または環境変数で設定） |

Aurora PostgreSQL Serverless Express クラスターは事前に作成済みで、IAM 認証が有効になっている必要があります。

## セットアップ

### 1. 依存パッケージのインストール

```bash
npm install
```

### 2. 環境変数の設定

```bash
cp .env.example .env
```

`.env` を編集して各値を設定します。各項目の詳細は `.env.example` を参照してください。

```
DB_HOST=my-express-cluster.cluster-xxxxxxxxxxxx.ap-northeast-1.rds.amazonaws.com
DB_USER=postgres
DB_NAME=postgres
AWS_REGION=ap-northeast-1
TZ=Asia/Tokyo
LOG_LEVEL=info
```

### 3. テーブルの作成（マイグレーション）

マイグレーション実行時は IAM 認証トークンを URL に含める必要があります。
`.env` の値を自動で読み込むので、以下をそのまま実行してください。

```bash
npm run db:migrate
```

### 4. サンプル実行

```bash
npm start
```

サーバーが起動したら curl で動作確認できます。

```bash
# 作成
curl -X POST http://localhost:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"クラスメソ太","email":"mesota@example.com"}'

curl -X POST http://localhost:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"クラスメソ子","email":"mesoko@example.com"}'

# 全件取得
curl http://localhost:3000/users

# 1件取得
curl http://localhost:3000/users/1

# 更新
curl -X PUT http://localhost:3000/users/1 \
  -H 'Content-Type: application/json' \
  -d '{"name":"クラスメソ次郎"}'

# 削除
curl -X DELETE http://localhost:3000/users/1
```

## ディレクトリ構成

```
.
├── src/
│   ├── db/
│   │   ├── index.ts      # DB接続設定（IAM認証トークン自動更新）
│   │   └── schema.ts     # スキーマ定義（usersテーブル）
│   ├── app.ts            # Hono ルート定義（REST API）
│   ├── index.ts          # サーバー起動エントリーポイント
│   └── logger.ts         # ロガー設定（pino）
├── scripts/
│   └── migrate.sh        # マイグレーション実行スクリプト
├── drizzle.config.ts      # Drizzle Kit 設定
├── .env.example           # 環境変数テンプレート
└── package.json
```
