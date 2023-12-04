import postgres from 'postgres'
import { drizzle } from 'drizzle-orm/postgres-js'

import { env } from '#/env.ts'
import * as schema from '~schema'

const client = postgres(env.DATABASE_URL_POOLED)

export const database = drizzle(client, {
  schema,
  logger: env.ENABLE_DATABASE_LOGGING === 'true'
})
