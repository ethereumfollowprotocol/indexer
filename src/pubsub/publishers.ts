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

  constructor(client: PublicClient, contractName: string, abi: any, address: `0x${string}`) {
    this.client = client
    this.contractName = contractName
    this.abi = abi
    this.address = address
  }

  subscribe(subscriber: EventSubscriber): void {
    if (subscriber.address !== this.address) {
      throw new Error(
        `Cannot subscribe to ${subscriber.contractName} with address ${subscriber.address} using publisher for ${this.contractName} with address ${this.address}`
      )
    }

    this.subscribers.push(subscriber)
    this.client.watchContractEvent({
      abi: subscriber.abi,
      address: subscriber.address,
      onLogs: logs => logs.forEach(log => subscriber.onLog(log)),
      onError: subscriber.onError
    })
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
