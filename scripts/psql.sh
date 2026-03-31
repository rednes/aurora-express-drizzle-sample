#!/bin/bash
# IAM 認証トークンを使って Aurora PostgreSQL に psql で接続するスクリプト
#
# 使い方:
#   bash scripts/psql.sh
#   または
#   npm run psql
set -euo pipefail

# .env から環境変数を読み込む
if [ -f .env ]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    [[ -n "$key" ]] && export "$key=$value"
  done < .env
fi

# 必須変数チェック
: "${DB_HOST:?DB_HOST が .env に設定されていません}"
: "${DB_USER:=postgres}"
: "${DB_NAME:=postgres}"
: "${AWS_REGION:=ap-northeast-1}"

echo "IAM 認証トークンを生成中..."
TOKEN=$(aws rds generate-db-auth-token \
  --hostname "$DB_HOST" \
  --port 5432 \
  --region "$AWS_REGION" \
  --username "$DB_USER")

echo "psql で接続します（${DB_USER}@${DB_HOST}/${DB_NAME}）..."
PGPASSWORD="$TOKEN" psql \
  "host=${DB_HOST} port=5432 dbname=${DB_NAME} user=${DB_USER} sslmode=require"
