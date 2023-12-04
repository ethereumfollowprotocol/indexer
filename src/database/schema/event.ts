import { sql } from 'drizzle-orm'
import * as s from 'drizzle-orm/pg-core'

export const event = s.pgTable(
  'events',
  {
    id: s.text('id').default(sql`generate_ulid()`).primaryKey().notNull(),
    transactionHash: s.varchar('transaction_hash', { length: 66 }).notNull(),
    blockNumber: s.text('block_number').notNull(), // Or integer, based on your requirements
    contractAddress: s.varchar('contract_address', { length: 42 }).notNull(),
    eventName: s.varchar('event_name', { length: 255 }).notNull(),
    eventParameters: s.jsonb('event_parameters').notNull(),
    timestamp: s.timestamp('timestamp', { withTimezone: true, mode: 'string' }).notNull(),
    processed: s.text('processed').default('false').notNull() // Or boolean, based on your requirements
  },
  table => {
    return {
      idxTransactionHash: s.index('idx_transaction_hash').on(table.transactionHash),
      idxContractAddress: s.index('idx_contract_address').on(table.contractAddress),
      idxEventName: s.index('idx_event_name').on(table.eventName),
      idxBlockNumber: s.index('idx_block_number').on(table.blockNumber)
    }
  }
)
