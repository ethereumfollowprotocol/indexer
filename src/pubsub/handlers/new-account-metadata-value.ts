import { database } from '#/database'
import { logger } from '#/logger'
import { sql, type QueryResult, type RawBuilder } from 'kysely'
import type { Event } from '../event'

export class NewAccountMetadataValueHandler {
  async onNewAccountMetadataValue(event: Event): Promise<void> {
    const address: `0x${string}` = event.eventParameters.args['addr']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__NewAccountMetadataValue(
      ${event.chainId},
      ${event.contractAddress},
      ${address},
      ${key},
      ${value}
    )`
    const eventSignature: string = `${event.eventParameters.eventName}(${address}, ${key}, ${value})`
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
