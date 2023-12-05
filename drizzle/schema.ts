import {
  pgTable,
  pgEnum,
  varchar,
  index,
  serial,
  integer,
  jsonb,
  timestamp,
  foreignKey,
  text,
  unique
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

export const action = pgEnum('action', ['unmute', 'mute', 'unblock', 'block', 'unfollow', 'follow'])

export const schemaMigrations = pgTable('schema_migrations', {
  version: varchar('version', { length: 128 }).primaryKey().notNull()
})

export const events = pgTable(
  'events',
  {
    id: serial('id').primaryKey().notNull(),
    transactionHash: varchar('transaction_hash', { length: 66 }).notNull(),
    blockNumber: integer('block_number').notNull(),
    contractAddress: varchar('contract_address', { length: 42 }).notNull(),
    eventName: varchar('event_name', { length: 255 }).notNull(),
    eventParameters: jsonb('event_parameters').notNull(),
    timestamp: timestamp('timestamp', { withTimezone: true, mode: 'string' }).notNull()
  },
  table => {
    return {
      idxTransactionHash: index('idx_transaction_hash').on(table.transactionHash),
      idxContractAddress: index('idx_contract_address').on(table.contractAddress),
      idxEventName: index('idx_event_name').on(table.eventName),
      idxBlockNumber: index('idx_block_number').on(table.blockNumber)
    }
  }
)

export const activity = pgTable(
  'activity',
  {
    id: text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    action: action('action').notNull(),
    actorAddress: varchar('actor_address')
      .notNull()
      .references(() => user.walletAddress, { onDelete: 'restrict', onUpdate: 'cascade' }),
    targetAddress: varchar('target_address').notNull(),
    actionTimestamp: timestamp('action_timestamp', {
      withTimezone: true,
      mode: 'string'
    }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull()
  },
  table => {
    return {
      indexActivityAction: index('index_activity_action').on(table.action),
      indexActivityActor: index('index_activity_actor').on(table.actorAddress),
      indexActivityTarget: index('index_activity_target').on(table.targetAddress)
    }
  }
)

export const user = pgTable(
  'user',
  {
    id: text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    walletAddress: varchar('wallet_address').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true, mode: 'string' })
      .default(sql`(now() AT TIME ZONE 'utc'::text)`)
      .notNull()
  },
  table => {
    return {
      userWalletAddressKey: unique('user_wallet_address_key').on(table.walletAddress)
    }
  }
)
