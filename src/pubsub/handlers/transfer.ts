import { database } from '#/database'
import { logger } from '#/logger'
import { sql, type QueryResult, type RawBuilder } from 'kysely'
import type { Address } from 'viem'
import type { Event } from '../event'

export class TransferHandler {
  async onTransfer(event: Event): Promise<void> {
    const from: Address = event.eventParameters.args['from']
    const to: Address = event.eventParameters.args['to']
    const tokenId: bigint = event.eventParameters.args['tokenId']
    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__Transfer(
      ${event.chainId},
      ${event.contractAddress},
      ${tokenId},
      ${from},
      ${to}
    )`
    const eventSignature: string = `${event.eventParameters.eventName}(${tokenId}, ${from}, ${to})`
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
