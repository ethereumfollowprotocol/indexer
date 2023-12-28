import { type QueryResult, type RawBuilder, sql } from 'kysely'
import { database } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class ListOpHandler {
  async onListOp(event: Event): Promise<void> {
    const nonce: bigint = event.eventParameters.args['nonce']
    const op: `0x${string}` = event.eventParameters.args['op']

    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__ListOp(
      ${event.chainId},
      ${event.contractAddress},
      ${nonce},
      ${op}
    )`
    const eventSignature: string = `${event.contractAddress} ${event.eventParameters.eventName}(${nonce}, ${op})`
    logger.info(eventSignature)

    try {
      const result: QueryResult<unknown> = await query.execute(database)
      // sleep for 1 sec
      await new Promise(resolve => setTimeout(resolve, 1000))

      if (!result || result.rows.length === 0) {
        logger.warn(`${eventSignature} query returned no rows`)
        return
      }
    } catch (error: any) {
      logger.error(`${eventSignature} Error processing event: ${error.message}`)
      process.exit(1)
    }
  }
}
