import { type QueryResult, type RawBuilder, sql } from 'kysely'
import type { Address } from 'viem'
import { database } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class OwnershipTransferredHandler {
  async onOwnershipTransferred(event: Event): Promise<void> {
    const contractName: string = event.contractName
    const previousOwner: Address = event.eventParameters.args['previousOwner']
    const newOwner: Address = event.eventParameters.args['newOwner']
    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__OwnershipTransferred(
      ${event.chainId},
      ${event.contractAddress},
      ${contractName},
      ${previousOwner},
      ${newOwner}
    )`
    const eventSignature: string = `${event.contractAddress} ${event.eventParameters.eventName}(${previousOwner}, ${newOwner})`
    logger.info(eventSignature)

    try {
      const result: QueryResult<unknown> = await query.execute(database)

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
