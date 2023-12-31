import { database } from '#/database'
import { logger } from '#/logger'
import { colors } from '#/utilities/colors'
import type { Event } from '../event'

/**
 * Interface defining the structure and methods for an EventSubscriber.
 */
export interface EventSubscriber {
  onEvent(event: Event): Promise<void>
}

function serializer<T>(_: string, value: T): T | number | string {
  if (typeof value !== 'bigint') {
    return value
  }
  // Convert bigint to number if within the safe range
  if (value <= BigInt(Number.MAX_SAFE_INTEGER)) {
    return Number(value)
  }
  // Otherwise, convert bigint to string
  return value.toString()
}

export class EventUploader implements EventSubscriber {
  async onEvent(event: Event): Promise<void> {
    const eventSignature: string = this.logEvent(event)

    const result = await database
      .insertInto('events')
      .values({
        chain_id: event.chainId,
        block_number: event.blockNumber,
        transaction_index: event.transactionIndex,
        log_index: event.logIndex,
        contract_address: event.contractAddress,
        event_name: event.eventParameters.eventName,
        event_args: JSON.stringify(event.eventParameters.args, serializer),
        block_hash: event.blockHash,
        transaction_hash: event.transactionHash,
        sort_key: `${event.blockNumber}-${event.transactionIndex}-${event.logIndex}`
      })
      .executeTakeFirst()
    if (result.numInsertedOrUpdatedRows !== 1n) {
      logger.error(`Failed to insert event ${eventSignature}`)
    }
  }

  logEvent(event: Event): string {
    const eventSignature: `${string}(${string})` = `${event.contractAddress} ${
      event.eventParameters.eventName
    }(${Object.values(event.eventParameters.args).join(', ')})`

    let s: string = eventSignature

    // choose color to log
    switch (event.eventParameters.eventName) {
      case 'ListOp':
        s = `${colors.LIGHT_MAGENTA}${eventSignature}${colors.ENDC}`
        break
      case 'MintStateChange':
        s = `${colors.LIGHT_MAGENTA}${eventSignature}${colors.ENDC}`
        break
      case 'OwnershipTransferred':
        s = `${colors.ORANGE}${eventSignature}${colors.ENDC}`
        break
      case 'ProxyAdded':
        s = `${colors.LIGHT_MAGENTA}${eventSignature}${colors.ENDC}`
        break
      case 'Transfer':
        if (event.eventParameters.args['from'] === '0x0000000000000000000000000000000000000000') {
          s = `${colors.GREEN}${eventSignature}${colors.ENDC}`
        } else {
          s = `${colors.BLUE}${eventSignature}${colors.ENDC}`
        }
        break
      case 'UpdateAccountMetadata':
        s = `${colors.LIGHT_BLUE}${eventSignature}${colors.ENDC}`
        break
      case 'UpdateListMetadataValue':
        s = `${colors.CYAN}${eventSignature}${colors.ENDC}`
        break
      case 'UpdateListStorageLocation':
        s = `${colors.LIGHT_BLUE}${eventSignature}${colors.ENDC}`
        break
      default:
        break
    }

    logger.info(s)

    return eventSignature
  }
}
