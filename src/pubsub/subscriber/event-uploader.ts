import { database } from '#/database'
import { logger } from '#/logger'
import type { Event } from '#/pubsub/event'
import type { EventSubscriber } from './interface'

export class EventUploader implements EventSubscriber {
  async onEvent(event: Event): Promise<void> {
    await this.onEvents([event])
    const rows = [EventUploader.#toTableRow(event)]
    const result = await database.insertInto('events').values(rows).executeTakeFirst()
    if (result.numInsertedOrUpdatedRows !== 1n) {
      logger.error(`Failed to insert event ${JSON.stringify(event)}`)
    }
  }

  async onEvents(events: Event[]): Promise<void> {
    if (events.length > 1) {
      logger.info(`⏳ Uploading ${events.length} events`)
    }
    for (const event of events) {
      logger.info(
        `📌 ${event.contractAddress} ${event.eventParameters.eventName}(${Object.values(
          event.eventParameters.args
        ).join(', ')})`
      )
    }
    const rows = events.map(event => EventUploader.#toTableRow(event))
    const result = await database.insertInto('events').values(rows).executeTakeFirst()
    logger.info(result)
    // sleep 1 sec
    await new Promise(resolve => setTimeout(resolve, 250))
    if (result.numInsertedOrUpdatedRows !== BigInt(events.length)) {
      logger.error(`Failed to insert events ${JSON.stringify(events)}`)
    }
    logger.info(`✅ Uploaded ${events.length} events`)
  }

  static #toTableRow(event: Event): {
    block_hash: string
    block_number: bigint
    chain_id: bigint
    contract_address: string
    event_args: string
    event_name: string
    log_index: number
    sort_key: string
    transaction_hash: string
    transaction_index: number
  } {
    return {
      chain_id: event.chainId,
      block_number: event.blockNumber,
      transaction_index: event.transactionIndex,
      log_index: event.logIndex,
      contract_address: event.contractAddress,
      event_name: event.eventParameters.eventName,
      event_args: JSON.parse(event.serializeArgs()) as any,
      block_hash: event.blockHash,
      transaction_hash: event.transactionHash,
      sort_key: event.sortKey()
    }
  }
}
