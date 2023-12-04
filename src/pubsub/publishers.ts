import {
  EFPAccountMetadataABI,
  EFPListMetadataABI,
  EFPListMinterABI,
  EFPListRecordsABI,
  EFPListRegistryABI
} from '#/abi'
import type { PublicClient } from 'viem'
import type { EventSubscriber } from './subscribers'

export class EventPublisher {
  private client: PublicClient
  private subscribers: EventSubscriber[] = []
  public readonly contractName: string
  public readonly abi: any
  public readonly address: `0x${string}`
  private unwatch: () => void = () => {}

  constructor(client: PublicClient, contractName: string, abi: any, address: `0x${string}`) {
    this.client = client
    this.contractName = contractName
    this.abi = abi
    this.address = address
    this.unwatch = () => {}
  }

  subscribe(subscriber: EventSubscriber): void {
    if (subscriber.address !== this.address) {
      throw new Error(
        `Cannot subscribe to ${subscriber.contractName} with address ${subscriber.address} using publisher for ${this.contractName} with address ${this.address}`
      )
    }

    this.subscribers.push(subscriber)
  }

  unsubscribe(subscriber: EventSubscriber): void {
    this.subscribers = this.subscribers.filter(
      existingSubscriber => existingSubscriber !== subscriber
    )
  }

  start(): void {
    // This Action will batch up all the event logs found within the pollingInterval, and invoke them via onLogs.
    this.unwatch = this.client.watchContractEvent({
      abi: this.abi,
      address: this.address,
      onLogs: logs =>
        logs.forEach(log => this.subscribers.forEach(subscriber => subscriber.onLog(log))),
      onError: error => this.subscribers.forEach(subscriber => subscriber.onError(error)),
      // Default: false for WebSocket Clients, true for non-WebSocket Clients
      poll: undefined
      // Default: 1000
      // pollingInterval: 1000,
    })
  }

  stop(): void {
    this.unwatch()
    this.unwatch = () => {}
  }
}

export class EFPAccountMetadataPublisher extends EventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPAccountMetadata', EFPAccountMetadataABI, address)
  }
}

export class EFPListMetadataPublisher extends EventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListMetadata', EFPListMetadataABI, address)
  }
}

export class EFPListRegistryPublisher extends EventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListRegistry', EFPListRegistryABI, address)
  }
}

export class EFPListRecordsPublisher extends EventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListRecords', EFPListRecordsABI, address)
  }
}

export class EFPListMinterPublisher extends EventPublisher {
  constructor(client: PublicClient, address: `0x${string}`) {
    super(client, 'EFPListMinter', EFPListMinterABI, address)
  }
}
