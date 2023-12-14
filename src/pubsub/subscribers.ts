import type { Abi } from 'viem'
import { EFPAccountMetadataABI, EFPListMinterABI, EFPListRecordsABI, EFPListRegistryABI } from '#/abi'
import { type Row, database } from '#/database'
import { logger } from '#/logger'
import { ListManagerChangeHandler } from '#/pubsub/handlers/list-manager-change'
import { ListOperationHandler } from '#/pubsub/handlers/list-operation'
import { ListStorageLocationChangeHandler } from '#/pubsub/handlers/list-storage-location-change'
import { NewAccountMetadataValueHandler } from '#/pubsub/handlers/new-account-metadata-value'
import { NewListMetadataValueHandler } from '#/pubsub/handlers/new-list-metadata-value'
import { OwnershipTransferredHandler } from '#/pubsub/handlers/ownership-transferred'
import { TransferHandler } from '#/pubsub/handlers/transfer'
import type { Event } from './event'

/**
 * Interface defining the structure and methods for an EventSubscriber.
 */
export interface EventSubscriber {
  onEvent(event: Event): Promise<void>
}

/**
 * Abstract base class representing a generic event subscriber for Ethereum
 * smart contracts. This class provides a common structure and functionalities
 * for event subscribers, which can be specialized for different Ethereum smart
 * contracts.
 */
export abstract class ContractEventSubscriber implements EventSubscriber {
  /**
   * Constructs an EventSubscriber.
   * @param contractName - The name of the contract, used for easier identification and logging.
   * @param abi - The ABI of the contract, used for decoding event logs.
   * @param address - The Ethereum address of the contract.
   */
  constructor(
    /** Contract name for easier identification. */
    public readonly contractName: string,

    /** ABI of the contract for decoding event logs. */
    public readonly abi: Abi,

    /** Ethereum address of the contract. */
    public readonly address: `0x${string}`
  ) {}

  /**
   * Generic handler for log events. This function should be overridden by subclasses to process each log.
   * @param log - The log to process.
   */
  async onEvent(event: Event): Promise<void> {
    // this.log(event)
  }

  /**
   * Default log processing implementation. Decodes the log and logs the output.
   * @param log - The log to process.
   */
  protected log(event: Event): void {
    function customSerializer(_: string, value: any): any {
      return typeof value === 'bigint' ? value.toString() : value
    }

    logger.log(`[${this.contractName}]`, JSON.parse(JSON.stringify(event, customSerializer, 2)))
  }
}

export class EFPAccountMetadataSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPAccountMetadata', EFPAccountMetadataABI, address)
  }
}

export class EFPListRegistrySubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRegistry', EFPListRegistryABI, address)
  }
}

export class EFPListRecordsSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRecords', EFPListRecordsABI, address)
  }
}

export class EFPListMinterSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListMinter', EFPListMinterABI, address)
  }
}

export class EventsTableUploader implements EventSubscriber {
  async onEvent(event: Event): Promise<void> {
    // eventParameters will have an args field
    const serializableEventParameters: { eventName: string; args: Record<string, any> } = {
      eventName: event.eventParameters.eventName,
      args: {}
    }
    for (const key in event.eventParameters.args) {
      // convert bigints to strings
      const value = event.eventParameters.args[key]
      serializableEventParameters.args[key] = typeof value === 'bigint' ? value.toString() : value
    }

    const row: Row<'events'> = {
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      contract_address: event.contractAddress,
      // problem: we don't have event name here
      event_name: event.eventParameters.eventName,
      event_parameters: JSON.stringify(serializableEventParameters)
    }

    logger.log(`(${event.eventParameters.eventName}) Insert event into \`events\` table`)
    await database.insertInto('events').values([row]).executeTakeFirst()
  }
}

export class EventDispatcher implements EventSubscriber {
  async onEvent(event: Event): Promise<void> {
    const eventName: string = event.eventParameters.eventName

    switch (eventName) {
      case 'ListManagerChange':
        await new ListManagerChangeHandler().onListManagerChange(event)
        break
      case 'ListOperation':
        await new ListOperationHandler().onListOperation(event)
        break
      case 'ListStorageLocationChange':
        await new ListStorageLocationChangeHandler().onListStorageLocationChange(event)
        break
      case 'NewAccountMetadataValue':
        await new NewAccountMetadataValueHandler().onNewAccountMetadataValue(event)
        break
      case 'NewListMetadataValue':
        await new NewListMetadataValueHandler().onNewListMetadataValue(event)
        break
      case 'OwnershipTransferred':
        await new OwnershipTransferredHandler().onOwnershipTransferred(event)
        break
      case 'Transfer':
        await new TransferHandler().onTransfer(event)
        break
      default:
        // Handle unknown event name if needed
        console.log(
          `Skipping unknown event name ${eventName} for contract ${event.contractName} at ${event.contractAddress}`
        )
        break
    }
  }
}
