import { Kysely, PostgresDialect, type InsertObject } from 'kysely'
import type { DB } from 'kysely-codegen'
import { Pool } from 'pg'

import { env } from '#/env.ts'

export type EventsRow = InsertObject<DB, 'events'>
export type ContractsRow = InsertObject<DB, 'contracts'>
export type ListNFTsRow = InsertObject<DB, 'list_nfts'>

export const database = new Kysely<DB>({
  dialect: new PostgresDialect({
    pool: new Pool({
      connectionString: env.DATABASE_URL_POOLED
    })
  })
})
