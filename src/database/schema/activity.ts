import { sql } from 'drizzle-orm'
import * as s from 'drizzle-orm/pg-core'
import { userTable } from './user'

export const action = s.pgEnum('action', [
  'follow',
  'unfollow',
  'block',
  'unblock',
  'mute',
  'unmute'
])

export const activityTable = s.pgTable(
  'activity',
  {
    id: s.text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    action: action('action').notNull(),
    actor_address: s
      .varchar('actor_address')
      .notNull()
      .references(() => userTable.wallet_address, { onDelete: 'restrict', onUpdate: 'cascade' }),
    target_address: s.varchar('target_address').notNull(),
    action_timestamp: s
      .timestamp('action_timestamp', {
        withTimezone: true,
        mode: 'string'
      })
      .notNull(),
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
      index_activity_actor: s.index('index_activity_actor').on(table.actor_address),
      index_activity_target: s.index('index_activity_target').on(table.target_address),
      index_activity_action: s.index('index_activity_action').on(table.action)
    }
  }
)
