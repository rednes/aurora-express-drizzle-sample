// ローカル開発用エントリーポイント。
// Lambda 環境では src/index.ts を使用する。
// dotenv/config は必ず最初に import する。
// 他のモジュール（db/index.ts など）が process.env を参照する前に .env を読み込む必要があるため。
import 'dotenv/config';
import { serve } from '@hono/node-server';
import app from './app.js';
import { logger } from './logger.js';

serve({ fetch: app.fetch, port: 3000 }, () =>
  logger.info('http://localhost:3000'),
);
