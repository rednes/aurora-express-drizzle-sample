// Lambda ハンドラーエントリーポイント。
// API Gateway（v1 REST API / v2 HTTP API）からのイベントを Hono アプリに渡す。
// Lambda は環境変数をネイティブに提供するため dotenv は不要。
import { handle } from 'hono/aws-lambda';
import app from './app.js';

export const handler = handle(app);
