#!/bin/bash
# Lambda デプロイパッケージを作成するスクリプト
# 生成物: lambda.zip（terraform/ から参照される）
#
# 使い方:
#   bash scripts/package.sh
#   または
#   npm run package
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ZIP_OUTPUT="${PROJECT_ROOT}/lambda.zip"

echo "==> TypeScript をビルドします..."
cd "${PROJECT_ROOT}"
npm run build

echo "==> 一時ディレクトリを作成します..."
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

# dist/src/ の中身をルートにコピー（Lambda ハンドラー = index.handler）
echo "==> コンパイル済みファイルをコピーします（dist/src/ → ZIP ルート）..."
cp -r "${PROJECT_ROOT}/dist/src/." "${TEMP_DIR}/"

# package.json をコピー（"type": "module" による ESM 検出に必要）
# package-lock.json は npm ci のために一時的にコピーし、ZIP には含めない
# npm ci --prefix は読み込むディレクトリも変わるため、cd してから実行する
echo "==> 本番依存関係をインストールします（devDependencies を除外）..."
cp "${PROJECT_ROOT}/package.json" "${TEMP_DIR}/package.json"
cp "${PROJECT_ROOT}/package-lock.json" "${TEMP_DIR}/package-lock.json"
cd "${TEMP_DIR}"
npm ci --omit=dev

echo "==> ZIP を作成します..."
rm -f "${ZIP_OUTPUT}"
zip -r "${ZIP_OUTPUT}" . --exclude "package-lock.json"

echo ""
echo "✓ lambda.zip を作成しました: ${ZIP_OUTPUT}"
echo "  サイズ: $(du -sh "${ZIP_OUTPUT}" | cut -f1)"
echo ""
echo "次のステップ:"
echo "  初回デプロイ:    cd terraform && cp terraform.tfvars.example terraform.tfvars && terraform init && terraform apply"
echo "  コードのみ更新:  aws lambda update-function-code --function-name aurora-express-drizzle-sample --zip-file fileb://lambda.zip"
