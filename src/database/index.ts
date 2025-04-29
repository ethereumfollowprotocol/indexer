import { type InsertObject, Kysely, type QueryExecutor } from 'kysely'
import { PostgresJSDialect } from 'kysely-postgres-js'
import postgres from 'postgres'

import { env } from '#/env.ts'
import type { DB } from './generated/index.ts'

export type Row<T extends keyof DB> = InsertObject<DB, T>
// @ts-ignore
let postgresClient = postgres(env.DATABASE_URL, { max: 1, debug: false, no_cache: true })
let kyselyInstance = new Kysely<DB>({
  dialect: new PostgresJSDialect({ postgres: postgresClient })
})

let retryTimeout: ReturnType<typeof setTimeout> | null = null
let reconnectCount = 0
let lastDisconnectAt: number | null = null
let isReconnecting = false

// Optional hook: users of this module can assign this to observe reconnection events
export let onReconnect: ((info: { reconnectCount: number; since: number | null }) => void) | null = null

function scheduleReconnect() {
  if (retryTimeout || isReconnecting) return
  lastDisconnectAt = Date.now()
  isReconnecting = true

  retryTimeout = setTimeout(async () => {
    retryTimeout = null
    try {
      await postgresClient.end({ timeout: 0 }) // clean shutdown of old client
      // @ts-ignore
      postgresClient = postgres(env.DATABASE_URL, { max: 1, debug: false, no_cache: true })
      kyselyInstance = new Kysely<DB>({
        dialect: new PostgresJSDialect({ postgres: postgresClient })
      })
      reconnectCount++
      isReconnecting = false
      console.log('[POSTGRES] Reconnected successfully')

      if (onReconnect) {
        onReconnect({ reconnectCount, since: lastDisconnectAt })
      }
    } catch (err) {
      console.error('[POSTGRES] Reconnection attempt failed:', err)
      isReconnecting = false
      scheduleReconnect()
    }
  }, 5000)
}

function wrapQueryErrorHandling<
  T extends QueryExecutor & { execute: Function; executeTakeFirst: Function; executeTakeFirstOrThrow: Function }
>(executor: T): T {
  const originalExecute = executor.execute
  const originalExecuteTakeFirst = executor.executeTakeFirst
  const originalExecuteTakeFirstOrThrow = executor.executeTakeFirstOrThrow

  executor.execute = async function (...args: any[]) {
    if (isReconnecting) throw new Error('[POSTGRES] Currently reconnecting — query blocked.')
    try {
      return await originalExecute.apply(this, args)
    } catch (err) {
      console.error('[POSTGRES] Query failed:', err)
      scheduleReconnect()
      throw err
    }
  }

  executor.executeTakeFirst = async function (...args: any[]) {
    if (isReconnecting) throw new Error('[POSTGRES] Currently reconnecting — query blocked.')
    try {
      return await originalExecuteTakeFirst.apply(this, args)
    } catch (err) {
      console.error('[POSTGRES] Query failed:', err)
      scheduleReconnect()
      throw err
    }
  }

  executor.executeTakeFirstOrThrow = async function (...args: any[]) {
    if (isReconnecting) throw new Error('[POSTGRES] Currently reconnecting — query blocked.')
    try {
      return await originalExecuteTakeFirstOrThrow.apply(this, args)
    } catch (err) {
      console.error('[POSTGRES] Query failed:', err)
      scheduleReconnect()
      throw err
    }
  }

  return executor
}

const database = new Proxy(kyselyInstance, {
  get(target, prop, receiver) {
    const value = Reflect.get(target, prop, receiver)
    if (typeof value === 'function') {
      return (...args: any[]) => {
        const result = value.apply(target, args)
        return result?.execute ? wrapQueryErrorHandling(result) : result
      }
    }
    return value
  }
})

export { database }
