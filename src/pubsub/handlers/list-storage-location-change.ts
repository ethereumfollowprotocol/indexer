import { database } from '#/database'
import { logger } from '#/logger'
import { sql, type QueryResult, type RawBuilder } from 'kysely'
import type { Event } from '../event'

export class ListStorageLocationChangeHandler {
  async onListStorageLocationChange(event: Event): Promise<void> {
    const tokenId: bigint = event.eventParameters.args['tokenId']
    const listStorageLocation: `0x${string}` = event.eventParameters.args['listStorageLocation']

    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__ListStorageLocationChange(
      ${event.chainId},
      ${event.contractAddress},
      ${tokenId},
      ${listStorageLocation}
    )`
    const eventSignature: string = `${event.eventParameters.eventName}(${tokenId}, ${listStorageLocation})`
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
