import * as s from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

export const userTable = s.pgTable(
  'user',
  {
    id: s.text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    wallet_address: s.varchar('wallet_address').notNull(),
    created_at: s
      .timestamp('created_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull(),
    updated_at: s
      .timestamp('updated_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull()
  },
  table => {
    return {
      user_wallet_address_key: s.unique('user_wallet_address_key').on(table.wallet_address)
    }
  }
)
