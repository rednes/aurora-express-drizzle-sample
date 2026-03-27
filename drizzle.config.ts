import 'dotenv/config';
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  // マイグレーションファイルの出力先ディレクトリ
  out: './drizzle',
  schema: './src/db/schema.ts',
  dialect: 'postgresql',
  dbCredentials: {
    // DATABASE_URL は npm run db:migrate 実行時に scripts/migrate.sh が
    // IAM 認証トークンを含む URL を生成して環境変数にセットする
    url: process.env.DATABASE_URL!,
  },
});
