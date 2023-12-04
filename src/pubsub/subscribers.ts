import {
  EFPAccountMetadataABI,
  EFPListMetadataABI,
  EFPListMinterABI,
  EFPListRecordsABI,
  EFPListRegistryABI
} from '#/abi'
import { logger } from '#/logger'
import { decodeEventLog, type Log } from 'viem'

/**
 * Abstract base class representing a generic event subscriber for Ethereum
 * smart contracts. This class provides a common structure and functionalities
 * for event subscribers, which can be specialized for different Ethereum smart
 * contracts.
 */
export abstract class EventSubscriber {
  /** Contract name for easier identification. */
  public readonly contractName: string

  /** ABI of the contract for decoding event logs. */
  public readonly abi: any

  /** Ethereum address of the contract. */
  public readonly address: `0x${string}`

  /**
   * Constructs an EventSubscriber.
   * @param contractName - The name of the contract, used for easier identification and logging.
   * @param abi - The ABI of the contract, used for decoding event logs.
   * @param address - The Ethereum address of the contract.
   */
  constructor(contractName: string, abi: any, address: `0x${string}`) {
    this.contractName = contractName
    this.abi = abi
    this.address = address
  }

  /**
   * Generic handler for log events. This function should be overridden by subclasses to process each log.
   * @param log - The log to process.
   */
  onLog(log: Log): void {
    this.log(log)
  }

  /**
   * Error handler for the event subscriber.
   * @param error - The error to be logged.
   */
  onError(error: Error): void {
    logger.error(`${this.contractName} error:`, error)
  }

  /**
   * Default log processing implementation. Decodes the log and logs the output.
   * @param log - The log to process.
   */
  protected log(log: Log): void {
    const { data, topics, transactionHash, blockNumber } = log
    const decodedTopics = decodeEventLog({ abi: this.abi, data, topics })

    const logEntry = {
      Contract: this.contractName,
      TransactionHash: transactionHash,
      BlockNumber: blockNumber !== null ? blockNumber.toString() : 'N/A',
      DecodedData: decodedTopics
    }

    function customSerializer(_: string, value: any): any {
      return typeof value === 'bigint' ? value.toString() : value
    }

    logger.log(
      `[${this.contractName}] Event Details:`,
      JSON.stringify(logEntry, customSerializer, 2)
    )
  }
}

export class EFPAccountMetadataSubscriber extends EventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPAccountMetadata', EFPAccountMetadataABI, address)
  }
}

export class EFPListMetadataSubscriber extends EventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListMetadata', EFPListMetadataABI, address)
  }
}

export class EFPListRegistrySubscriber extends EventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRegistry', EFPListRegistryABI, address)
  }
}

export class EFPListRecordsSubscriber extends EventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRecords', EFPListRecordsABI, address)
  }
}

export class EFPListMinterSubscriber extends EventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListMinter', EFPListMinterABI, address)
  }
}
