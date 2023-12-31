import { type QueryResult, type RawBuilder, sql } from 'kysely'
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

    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event(
      ${event.chainId},
      ${event.blockNumber},
      ${event.transactionIndex},
      ${event.logIndex},
      ${event.contractAddress},
      ${event.contractName},
      ${event.eventParameters.eventName},
      ${JSON.parse(JSON.stringify(event.eventParameters.args, serializer))},
      ${event.blockHash},
      ${event.transactionHash}
    )`

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

  logEvent(event: Event): `${string}(${string})` {
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
