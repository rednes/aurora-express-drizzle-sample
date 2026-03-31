// pino: Node.js向けの高速なロガーライブラリ
// pino-pretty: ログを人間が読みやすい形式に整形するトランスポート（ローカル開発時のみ使用）
import pino from 'pino';

// IS_LOCAL=true のときのみ pino-pretty を使用する。
// Lambda 環境では JSON 形式で CloudWatch Logs に出力する（pino のデフォルト動作）。
const isLocal = process.env.IS_LOCAL === 'true';

export const logger = pino({
  // LOG_LEVEL 環境変数でレベルを切り替え可能（debug / info / warn / error）
  level: process.env.LOG_LEVEL ?? 'info',
  ...(isLocal && { transport: { target: 'pino-pretty' } }),
});
