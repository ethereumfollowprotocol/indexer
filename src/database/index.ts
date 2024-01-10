import { type InsertObject, Kysely } from 'kysely'
import { PostgresJSDialect } from 'kysely-postgres-js'
import postgres from 'postgres'

import { env } from '#/env.ts'
import type { DB } from './generated/index.ts'

export type Row<T extends keyof DB> = InsertObject<DB, T>

export const postgresClient = postgres(env.DATABASE_URL)

export const database = new Kysely<DB>({
  // @ts-expect-error
  dialect: new PostgresJSDialect({
    postgres: postgresClient
  })
})
