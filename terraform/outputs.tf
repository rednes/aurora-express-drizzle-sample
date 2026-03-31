output "api_url" {
  description = "API Gateway HTTP API のベース URL（$default ステージはパスプレフィックスなし）"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda 関数名"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "Lambda 関数の ARN"
  value       = aws_lambda_function.this.arn
}

output "lambda_log_group_name" {
  description = "Lambda の CloudWatch ロググループ名"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_iam_role_arn" {
  description = "Lambda 実行ロールの ARN"
  value       = aws_iam_role.this.arn
}
