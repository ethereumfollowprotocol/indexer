import { type InsertObject, Kysely } from 'kysely'
import { PostgresJSDialect } from 'kysely-postgres-js'
import postgres from 'postgres'

import { env } from '#/env.ts'
import type { DB } from './generated/index.ts'

export type Row<T extends keyof DB> = InsertObject<DB, T>

let postgresClient = postgres(env.DATABASE_URL)
let kyselyInstance = new Kysely<DB>({
  dialect: new PostgresJSDialect({ postgres: postgresClient })
})

let retryTimeout: ReturnType<typeof setTimeout> | null = null

function scheduleReconnect() {
  if (retryTimeout) return
  retryTimeout = setTimeout(() => {
    retryTimeout = null
    try {
      postgresClient = postgres(env.DATABASE_URL)
      kyselyInstance = new Kysely<DB>({
        dialect: new PostgresJSDialect({ postgres: postgresClient })
      })
      console.log('[POSTGRES] Reconnected successfully')
    } catch (err) {
      console.error('[POSTGRES] Reconnection attempt failed:', err)
      scheduleReconnect()
    }
  }, 5000)
}

const database: Kysely<DB> = new Proxy({} as Kysely<DB>, {
  get(_, prop) {
    const target = kyselyInstance[prop as keyof Kysely<DB>]

    if (typeof target === 'function') {
      return (...args: any[]) => {
        try {
          return (kyselyInstance[prop as keyof Kysely<DB>] as any)(...args)
        } catch (err) {
          console.error(`[POSTGRES] Kysely method ${String(prop)} failed:`, err)
          scheduleReconnect()
          throw err
        }
      }
    }

    return target
  }
})

export { database }
