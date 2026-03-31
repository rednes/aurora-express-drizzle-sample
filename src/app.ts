import { Hono } from 'hono';
import { eq } from 'drizzle-orm';
import { db } from './db/index.js';
import { usersTable } from './db/schema.js';
import { logger } from './logger.js';

const app = new Hono();

// Lambda インスタンス識別用ヘッダー（ローカル環境では未設定のため省略される）
const logStreamName = process.env.AWS_LAMBDA_LOG_STREAM_NAME;
if (logStreamName) {
  app.use('*', async (c, next) => {
    await next();
    c.res.headers.set('X-Lambda-Log-Stream', logStreamName);
  });
}

// Number() は "abc" に対して NaN を返すため、parseInt + isNaN で安全に変換する
const parseId = (raw: string) => {
  const id = parseInt(raw, 10);
  return isNaN(id) ? null : id;
};

// GET /users - 全件取得
app.get('/users', async (c) => {
  const users = await db.select().from(usersTable);
  return c.json(users);
});

// GET /users/:id - 1件取得
app.get('/users/:id', async (c) => {
  const id = parseId(c.req.param('id'));
  if (id === null) return c.json({ error: 'Invalid id' }, 400);
  // Drizzle は常に配列を返すため、先頭要素を分割代入で取り出す
  const [user] = await db.select().from(usersTable).where(eq(usersTable.id, id));
  if (!user) return c.json({ error: 'Not Found' }, 404);
  return c.json(user);
});

// POST /users - 作成
app.post('/users', async (c) => {
  const { name, email } = await c.req.json<{ name: string; email: string }>();
  try {
    // returning() で INSERT されたレコードをそのまま返す
    const [user] = await db.insert(usersTable).values({ name, email }).returning();
    return c.json(user, 201);
  } catch (e: any) {
    // 23505: PostgreSQL の unique 制約違反エラーコード
    // Drizzle が DrizzleQueryError でラップするため e.cause.code も確認する
    if (e.code === '23505' || (e.cause as any)?.code === '23505')
      return c.json({ error: 'email already exists' }, 409);
    throw e;
  }
});

// PUT /users/:id - 更新
app.put('/users/:id', async (c) => {
  const id = parseId(c.req.param('id'));
  if (id === null) return c.json({ error: 'Invalid id' }, 400);
  const { name } = await c.req.json<{ name: string }>();
  // returning() で UPDATE 後のレコードを返す
  const [user] = await db.update(usersTable)
    .set({ name })
    .where(eq(usersTable.id, id))
    .returning();
  if (!user) return c.json({ error: 'Not Found' }, 404);
  return c.json(user);
});

// DELETE /users/:id - 削除
app.delete('/users/:id', async (c) => {
  const id = parseId(c.req.param('id'));
  if (id === null) return c.json({ error: 'Invalid id' }, 400);
  // returning() で削除されたレコードを返す（存在チェックにも使える）
  const [user] = await db.delete(usersTable)
    .where(eq(usersTable.id, id))
    .returning();
  if (!user) return c.json({ error: 'Not Found' }, 404);
  return c.json(user);
});

// IAM トークン期限切れ（28P01）は 503 を返す。その他の未処理エラーは 500 を返す。
// Drizzle が DrizzleQueryError でラップするため、err.cause?.code も確認する。
app.onError((err, c) => {
  const code = (err as any).code ?? (err as any).cause?.code;
  if (code === '28P01') {
    logger.error({ err }, '[app] database authentication failed');
    return c.json({ error: 'Service temporarily unavailable' }, 503);
  }
  logger.error({ err }, '[app] unhandled error');
  return c.json({ error: 'Internal Server Error' }, 500);
});

export default app;
