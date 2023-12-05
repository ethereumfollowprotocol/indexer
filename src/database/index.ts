import { Pool } from 'pg'
import type { DB } from 'kysely-codegen'
import { Kysely, PostgresDialect } from 'kysely'

import { env } from '#/env.ts'

export const database = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new Pool({
      connectionString: env.DATABASE_URL_POOLED
    })
  })
})
