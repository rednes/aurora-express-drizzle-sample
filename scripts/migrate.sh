#!/bin/bash
set -e

# .env から環境変数を読み込む
if [ -f .env ]; then
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

# 必須変数チェック
: "${DB_HOST:?DB_HOST が .env に設定されていません}"
: "${DB_USER:=postgres}"
: "${DB_NAME:=postgres}"
: "${AWS_REGION:=ap-northeast-1}"

echo "IAM認証トークンを生成中..."
TOKEN=$(aws rds generate-db-auth-token \
  --hostname "$DB_HOST" \
  --port 5432 \
  --region "$AWS_REGION" \
  --username "$DB_USER")

ENCODED_TOKEN=$(node -e "process.stdout.write(encodeURIComponent(process.argv[1]))" "$TOKEN")

export DATABASE_URL="postgresql://${DB_USER}:${ENCODED_TOKEN}@${DB_HOST}:5432/${DB_NAME}?sslmode=verify-full"

echo "マイグレーションを実行中..."
npx drizzle-kit push
