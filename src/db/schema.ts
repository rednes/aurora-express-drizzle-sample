import { integer, pgTable, varchar, timestamp } from 'drizzle-orm/pg-core';

export const usersTable = pgTable('users', {
  // generatedAlwaysAsIdentity: INSERT 時に DB 側で自動採番される（手動指定不可）
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar({ length: 255 }).notNull(),
  // unique: 同じメールアドレスの重複登録を DB レベルで防ぐ
  email: varchar({ length: 255 }).notNull().unique(),
  // defaultNow: INSERT 時に DB サーバー側の現在時刻が自動でセットされる
  createdAt: timestamp().defaultNow().notNull(),
});
