import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import { Signer } from '@aws-sdk/rds-signer';
import { logger } from '../logger.js';

const { DB_HOST, DB_USER = 'postgres', DB_NAME = 'postgres', AWS_REGION = 'ap-northeast-1' } = process.env;
if (!DB_HOST) throw new Error('DB_HOST is not set');

// Aurora PostgreSQL Express は IAM 認証のみをサポートしているため、
// @aws-sdk/rds-signer を使って IAM 認証トークンを生成する。
// トークンは署名付き URL 形式で、有効期限は15分。
const signer = new Signer({
  hostname: DB_HOST,
  port: 5432,
  username: DB_USER,
  region: AWS_REGION,
});

// sv-SE ロケールは "YYYY-MM-DD HH:MM:SS" 形式で出力されるため ISO 形式に近く扱いやすい。
// TZ 環境変数（例: Asia/Tokyo）を設定すると JST などのローカル時刻で表示できる。
// Lambda ランタイムは TZ=:UTC（POSIX 形式）を自動設定するが、toLocaleString は
// コロン付きのタイムゾーン指定を受け付けないため、先頭のコロンを除去する。
const formatDate = (d: Date) =>
  d.toLocaleString('sv-SE', { timeZone: (process.env.TZ ?? 'UTC').replace(/^:/, ''), hour12: false }).replace(' ', 'T');

// IAM 認証トークンは15分有効。有効期限内はキャッシュを使い回し、
// 期限切れ5分前になったら次の接続時に自動で再取得する。
const TOKEN_TTL_MS = 15 * 60 * 1000;
// 期限ぎりぎりでの接続中にトークンが切れるのを防ぐためのバッファ
const TOKEN_REFRESH_BUFFER_MS = 5 * 60 * 1000;
let cachedToken = '';
let tokenExpiresAt = 0;

async function getAuthToken(): Promise<string> {
  logger.info('[getAuthToken] called');
  if (Date.now() < tokenExpiresAt - TOKEN_REFRESH_BUFFER_MS) {
    logger.info(`[getAuthToken] cache hit. expires at ${formatDate(new Date(tokenExpiresAt))}`);
    return cachedToken;
  }
  logger.info('[getAuthToken] cache miss. fetching new token...');
  try {
    cachedToken = await signer.getAuthToken();
    tokenExpiresAt = Date.now() + TOKEN_TTL_MS;
    logger.info(`[getAuthToken] token fetched. expires at ${formatDate(new Date(tokenExpiresAt))}`);
  } catch (err) {
    logger.error({ err }, '[getAuthToken] failed to fetch token');
    throw err;
  }
  return cachedToken;
}

logger.info('[db/index] module initialized');

const pool = new Pool({
  host: DB_HOST,
  port: 5432,
  user: DB_USER,
  database: DB_NAME,
  // サーバー証明書を検証して中間者攻撃を防ぐ
  ssl: { rejectUnauthorized: true },
  // 接続数を1に制限（このサンプルでは1接続で十分）
  max: 1,
  // Aurora Serverless はサーバー側で約5分でアイドル接続を切断するため、それより短い4分に設定。
  idleTimeoutMillis: 4 * 60 * 1000,
  // Aurora Serverless のコールドスタート時に接続が無限に待ち続けないようタイムアウトを設定する。
  connectionTimeoutMillis: 30 * 1000,
  // password に関数を渡すと、pg が新しい接続を確立するたびに呼び出される。
  // IAM 認証トークンには有効期限があるため、値ではなく関数参照を渡して動的に取得する。
  password: getAuthToken,
});

pool.on('connect', () => logger.info('[pool] new connection established'));
pool.on('error', (err) => logger.error({ err }, '[pool] connection error'));

// pool.query をラップして、クエリ実行後に結果行数をログ出力し、エラー時にもログを残す。
// Drizzle の logger は実行前しか呼ばれないため、結果とエラーのログはここで補う。
const origQuery = pool.query.bind(pool);
(pool as any).query = (...args: any[]) =>
  Promise.resolve((origQuery as any)(...args))
    .then((r: any) => {
      logger.info(`[db] result: ${r.rowCount ?? 0} rows`);
      return r;
    })
    .catch((err: unknown) => {
      logger.error({ err }, '[db] query error');
      throw err;
    });

export const db = drizzle({
  client: pool,
  // Drizzle の logger はクエリ実行前に呼ばれる
  logger: { logQuery: (sql, params) => logger.info(`[db] query: ${sql} -- ${JSON.stringify(params)}`) },
});
