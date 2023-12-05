import { Pool } from 'pg'
import { Kysely, PostgresDialect, type InsertObject } from 'kysely'

import { env } from '#/env.ts'
import type { DB } from './generated/index.ts'

export type Row<T extends keyof DB> = InsertObject<DB, T>

export const database = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new Pool({
      connectionString: env.DATABASE_URL_POOLED
    })
  })
})
