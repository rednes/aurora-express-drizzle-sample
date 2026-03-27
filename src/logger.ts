// pino: Node.js向けの高速なロガーライブラリ
// pino-pretty: ログを人間が読みやすい形式に整形するトランスポート
import pino from 'pino';

export const logger = pino({
  // LOG_LEVEL 環境変数でレベルを切り替え可能（debug / info / warn / error）
  level: process.env.LOG_LEVEL ?? 'info',
  transport: { target: 'pino-pretty' },
});
