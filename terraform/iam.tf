# Lambda 実行ロール
resource "aws_iam_role" "this" {
  name = "${var.function_name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# CloudWatch Logs への書き込み権限
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Aurora IAM 認証権限（rds-db:connect）
resource "aws_iam_role_policy" "rds_iam_connect" {
  name = "${var.function_name}-rds-iam-connect"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "rds-db:connect"
      # dbuser:* でクラスター ID を固定しない。db_user（IAM 認証ユーザー）のみで制限する
      Resource = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:*/${var.db_user}"
    }]
  })
}
