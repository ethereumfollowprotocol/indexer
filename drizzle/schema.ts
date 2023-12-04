import {
  pgTable,
  unique,
  pgEnum,
  text,
  varchar,
  timestamp,
  index,
  foreignKey
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

export const action = pgEnum('action', ['unmute', 'mute', 'unblock', 'block', 'unfollow', 'follow'])

export const user = pgTable(
  'user',
  {
    id: text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    wallet_address: varchar('wallet_address').notNull(),
    created_at: timestamp('created_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull(),
    updated_at: timestamp('updated_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull()
  },
  table => {
    return {
      user_wallet_address_key: unique('user_wallet_address_key').on(table.wallet_address)
    }
  }
)

export const activity = pgTable(
  'activity',
  {
    id: text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    action: action('action').notNull(),
    actor_address: varchar('actor_address')
      .notNull()
      .references(() => user.wallet_address, { onDelete: 'restrict', onUpdate: 'cascade' }),
    target_address: varchar('target_address').notNull(),
    action_timestamp: timestamp('action_timestamp', {
      withTimezone: true,
      mode: 'string'
    }).notNull(),
    created_at: timestamp('created_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull(),
    updated_at: timestamp('updated_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull()
  },
  table => {
    return {
      index_activity_actor: index('index_activity_actor').on(table.actor_address),
      index_activity_target: index('index_activity_target').on(table.target_address),
      index_activity_action: index('index_activity_action').on(table.action)
    }
  }
)
