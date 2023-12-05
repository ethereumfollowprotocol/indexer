import {
  EFPAccountMetadataABI,
  EFPListMetadataABI,
  EFPListMinterABI,
  EFPListRecordsABI,
  EFPListRegistryABI
} from '#/abi'
import { logger } from '#/logger'
import type { Abi, PublicClient } from 'viem'
import { decodeLogtoEvent, type Event } from './event'
import { ContractEventSubscriber, type EventSubscriber } from './subscribers'

/**
 * Interface defining the structure and methods for an EventPublisher.
 */
export interface EventPublisher {
  subscribe(subscriber: EventSubscriber): void
  unsubscribe(subscriber: EventSubscriber): void
  start(): void
  stop(): void
}

/**
 * Concrete implementation of EventPublisher for handling contract events.
 */
export class ContractEventPublisher implements EventPublisher {
  private client: PublicClient
  private subscribers: EventSubscriber[] = []
  public readonly contractName: string
  public readonly abi: Abi
  public readonly address: `0x${string}`
  private unwatch: () => void = () => {}

  /**
   * Creates an instance of ContractEventPublisher.
   * @param client - The PublicClient used to interact with the blockchain.
   * @param contractName - The name of the contract.
   * @param abi - The ABI of the contract.
   * @param address - The Ethereum address of the contract.
   */
  constructor(client: PublicClient, contractName: string, abi: any, address: `0x${string}`) {
    this.client = client
    this.contractName = contractName
    this.abi = abi
    this.address = address
    this.unwatch = () => {
      logger.warn('ContractEventPublisher unwatch function not yet implemented')
    }
  }

  /**
   * Subscribes an EventSubscriber to this publisher.
   * Checks if the subscriber is a ContractEventSubscriber with a matching address.
   * @param subscriber - The EventSubscriber to subscribe.
   * @throws Will throw an error if the subscriber's address does not match the publisher's address.
   */
  subscribe(subscriber: EventSubscriber): void {
    if (subscriber instanceof ContractEventSubscriber && subscriber.address !== this.address) {
      throw new Error(
        `Cannot subscribe to ${subscriber.contractName} with address ${subscriber.address} using publisher for ${this.contractName} with address ${this.address}`
      )
    }

    this.subscribers.push(subscriber)
  }

  /**
   * Unsubscribes an EventSubscriber from this publisher.
   * @param subscriber - The EventSubscriber to unsubscribe.
   */
  unsubscribe(subscriber: EventSubscriber): void {
    this.subscribers = this.subscribers.filter(
      existingSubscriber => existingSubscriber !== subscriber
    )
  }

  /**
   * Starts the event listening process.
   * It sets up a listener for contract events and dispatches them to all subscribers.
   */
  start(): void {
    // This Action will batch up all the event logs found within the pollingInterval, and invoke them via onLogs.
    this.unwatch = this.client.watchContractEvent({
      abi: this.abi,
      address: this.address,
      onLogs: logs =>
        logs.forEach(async log => {
          const event: Event = decodeLogtoEvent(this.contractName, this.abi, log)
          await Promise.all(this.subscribers.map(subscriber => subscriber.onEvent(event)))
        }),
      onError: error => {
        logger.error(`${this.contractName} error:`, error)
      },
      // Default: false for WebSocket Clients, true for non-WebSocket Clients
      poll: undefined
      // Default: 1000
      // pollingInterval: 1000,
    })
  }

  /**
   * Stops the event listening process.
   * It disconnects the event listener and resets the unwatch function.
   */
  stop(): void {
    this.unwatch()
    this.unwatch = () => {}
  }
}

// The following classes are specific implementations of ContractEventPublisher for various contracts.
// Each class sets the appropriate contract details (name, ABI, address) upon instantiation.

export class EFPAccountMetadataPublisher extends ContractEventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPAccountMetadata', EFPAccountMetadataABI, address)
  }
}

export class EFPListMetadataPublisher extends ContractEventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListMetadata', EFPListMetadataABI, address)
  }
}

export class EFPListRegistryPublisher extends ContractEventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListRegistry', EFPListRegistryABI, address)
  }
}

export class EFPListRecordsPublisher extends ContractEventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListRecords', EFPListRecordsABI, address)
  }
}

export class EFPListMinterPublisher extends ContractEventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListMinter', EFPListMinterABI, address)
  }
}
