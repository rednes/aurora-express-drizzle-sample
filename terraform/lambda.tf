# Lambda 関数
# デプロイ前に `npm run package` で lambda.zip を作成しておく必要がある
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.this.arn

  # lambda.zip は terraform/ の一つ上のディレクトリ（プロジェクトルート）に配置される
  # terraform apply の前に `npm run package` で lambda.zip を作成しておく必要がある
  filename = "${path.module}/../lambda.zip"
  # try() で lambda.zip が存在しない場合の validate エラーを回避する
  # ファイルが存在する場合はハッシュを計算し、ZIP 変更時に Lambda コードを更新する
  source_code_hash = try(filebase64sha256("${path.module}/../lambda.zip"), null)

  # ZIP ルートに index.js が配置されるため handler は index.handler
  handler = "index.handler"
  runtime = "nodejs22.x"

  architectures = ["arm64"]
  timeout       = 40
  memory_size   = 128

  environment {
    variables = {
      DB_HOST   = var.db_host
      DB_USER   = var.db_user
      DB_NAME   = var.db_name
      LOG_LEVEL = var.log_level
      TZ        = var.tz
      # AWS_REGION は Lambda の予約済み環境変数のため設定しない（ランタイムが自動で設定）
      # IS_LOCAL は Lambda では設定しない（JSON ログを CloudWatch Logs へ出力する）
    }
  }

  tags = local.common_tags
}

# CloudWatch ロググループ（保持期間を管理するため明示的に定義）
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14

  tags = local.common_tags
}
