# HTTP API (v2)
# Hono がルーティングを内部で処理するため $default ルートで全リクエストを Lambda に転送する
resource "aws_apigatewayv2_api" "this" {
  name          = var.function_name
  protocol_type = "HTTP"

  tags = local.common_tags
}

# Lambda プロキシ統合（payload format version 2.0）
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.this.invoke_arn
  payload_format_version = "2.0"
}

# $default ルート：全パス・全メソッドを Lambda へ転送
resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# $default ステージ（auto_deploy = true でデプロイ手順が不要）
# $default ステージは URL にパスプレフィックスが付かないため
# エンドポイントは https://<id>.execute-api.<region>.amazonaws.com/users のような形式になる
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = local.common_tags
}

# API Gateway から Lambda を呼び出す権限
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  # /*/*：任意のステージ・任意のルートからの呼び出しを許可
  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
