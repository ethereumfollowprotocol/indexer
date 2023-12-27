import { database } from '#/database'
import { logger } from '#/logger'
import { sql, type QueryResult, type RawBuilder } from 'kysely'
import type { Address } from 'viem'
import type { Event } from '../event'

export class OwnershipTransferredHandler {
  async onOwnershipTransferred(event: Event): Promise<void> {
    const chainId: bigint = event.chainId
    const contractAddress: Address = event.contractAddress
    const contractName: string = event.contractName
    const previousOwner: Address = event.eventParameters.args['previousOwner']
    const newOwner: Address = event.eventParameters.args['newOwner']
    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__ownership_transferred(
      ${chainId},
      ${contractAddress},
      ${contractName},
      ${previousOwner},
      ${newOwner}
    )`
    const eventSignature: string = `OwnershipTransferred(${previousOwner}, ${newOwner})`
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
