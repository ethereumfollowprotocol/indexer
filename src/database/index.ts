import { Pool } from 'pg'
import type { DB } from 'kysely-codegen'
import { Kysely, PostgresDialect, type InsertObject } from 'kysely'

import { env } from '#/env.ts'

export type EventsRow = InsertObject<DB, 'events'>
export type UserRow = InsertObject<DB, 'user'>
export type ActivityRow = InsertObject<DB, 'activity'>

export const database = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new Pool({
      connectionString: env.DATABASE_URL_POOLED
    })
  })
})
