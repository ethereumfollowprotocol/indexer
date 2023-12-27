import { efpAccountMetadataAbi, efpListMinterAbi, efpListRecordsAbi, efpListRegistryAbi } from '#/abi'
import type { EvmClient } from '#/clients'
import { logger } from '#/logger'
import { compareEvents, createEventSignature, decodeLogtoEvent, type Event } from '#/pubsub/event'
import { ContractEventSubscriber, type EventSubscriber } from '#/pubsub/subscribers'
import { raise } from '#/utilities'
import { parseAbiItem, type Abi, type Log } from 'viem'

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
  private subscribers: EventSubscriber[] = []
  private unwatch: () => void = () => {}

  /**
   * Creates an instance of ContractEventPublisher.
   * @param client - The PublicClient used to interact with the blockchain.
   * @param chainId - The chain ID of the blockchain.
   * @param contractName - The name of the contract.
   * @param abi - The ABI of the contract.
   * @param address - The Ethereum address of the contract.
   */
  constructor(
    private client: EvmClient,
    public readonly chainId: bigint,
    public readonly contractName: string,
    public readonly abi: Abi,
    public readonly address: `0x${string}`
  ) {
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
    this.subscribers = this.subscribers.filter(existingSubscriber => existingSubscriber !== subscriber)
  }

  private async fetchHistoricalEvents(fromBlock: bigint, toBlock: bigint): Promise<void> {
    const eventSignatures: string[] = this.abi
      .filter((item: any) => item.type === 'event')
      .map((item: any) => createEventSignature(item))

    const logs: Log[] = []
    for (const eventSignature of eventSignatures) {
      try {
        const eventLogs = await this.client.getLogs({
          event: parseAbiItem(eventSignature) as any,
          address: this.address,
          fromBlock,
          toBlock
        })
        console.log(
          `Fetched ${eventLogs.length} log${
            eventLogs.length === 1 ? '' : 's'
          } from block ${fromBlock} to ${toBlock} for ${this.contractName} ${eventSignature}`
        )
        logs.push(...eventLogs)
      } catch (error) {
        logger.error(`Error fetching historical logs for ${this.contractName}:`, error)
        throw error
      }
    }

    await this.processLogs(logs)
  }

  private async processLogs(logs: Log[]): Promise<void> {
    logs.sort(compareEvents)

    // Process each log
    for (const log of logs) {
      // Assuming logIndex validation and other checks are done here
      const event: Event = decodeLogtoEvent(this.chainId, this.contractName, this.abi, log)
      await Promise.all(this.subscribers.map(subscriber => subscriber.onEvent(event)))
    }
  }

  /**
   * Starts the event listening process.
   * It sets up a listener for contract events and dispatches them to all subscribers.
   */
  async start(): Promise<void> {
    // Fetch and process historical events
    const latestBlock = await this.client.getBlockNumber()
    await this.fetchHistoricalEvents(0n, latestBlock)

    // This Action will batch up all the event logs found within the pollingInterval, and invoke them via onLogs.
    this.unwatch = this.client.watchContractEvent({
      abi: this.abi,
      address: this.address,
      onLogs: logs =>
        this.processLogs(logs).catch(error => {
          logger.error(`Error processing logs for ${this.contractName}:`, error)
          raise(error) // Assuming raise is a custom error handling function
        }),
      onError: error => {
        logger.error(`${this.contractName} error:`, error)
        raise(error)
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
    logger.log(`Stopping ${this.contractName} (${this.address}) event publisher`)
    this.unwatch()
    this.unwatch = () => {}
  }
}

// The following classes are specific implementations of ContractEventPublisher for various contracts.
// Each class sets the appropriate contract details (name, ABI, address) upon instantiation.

export class EFPAccountMetadataPublisher extends ContractEventPublisher {
  constructor(client: EvmClient, chainId: bigint, address: `0x${string}`) {
    super(client, chainId, 'EFPAccountMetadata', efpAccountMetadataAbi, address)
  }
}

export class EFPListRegistryPublisher extends ContractEventPublisher {
  constructor(client: EvmClient, chainId: bigint, address: `0x${string}`) {
    super(client, chainId, 'EFPListRegistry', efpListRegistryAbi, address)
  }
}

export class EFPListRecordsPublisher extends ContractEventPublisher {
  constructor(client: EvmClient, chainId: bigint, address: `0x${string}`) {
    super(client, chainId, 'EFPListRecords', efpListRecordsAbi, address)
  }
}

export class EFPListMinterPublisher extends ContractEventPublisher {
  constructor(client: EvmClient, chainId: bigint, address: `0x${string}`) {
    super(client, chainId, 'EFPListMinter', efpListMinterAbi, address)
  }
}

type ReceivedEvent = {
  // the event
  event: Event
  // the time it was received
  receivedAt: Date
}

/**
 * Concrete implementation of EventPublisher for interleaving disparate
 * event streams from multiple upstream publishers into a single
 * time-ordered stream of events.
 */
export class EventInterleaver implements EventPublisher, EventSubscriber {
  private readonly priorityQueue: ReceivedEvent[] = []
  private subscribers: EventSubscriber[] = []

  // Delay before propagating events to ensure time ordering.
  private readonly propagationDelay: number = 5000

  // Interval at which the queue is checked and processed.
  private readonly daemonInterval: number = 1000

  // Timer for the repeating process. Null when not running.
  private daemonTimer: NodeJS.Timeout | null = null

  // Flag to prevent concurrent processing.
  private isProcessing = false

  /**
   * Subscribe a new event subscriber.
   * @param subscriber - The subscriber to be added.
   */
  subscribe(subscriber: EventSubscriber): void {
    this.subscribers.push(subscriber)
  }

  /**
   * Unsubscribe an existing event subscriber.
   * @param subscriber - The subscriber to be removed.
   */
  unsubscribe(subscriber: EventSubscriber): void {
    this.subscribers = this.subscribers.filter(existingSubscriber => existingSubscriber !== subscriber)
  }

  /**
   * Start the event interleaving process.
   * Initializes and starts a timer to process the event queue at regular intervals.
   * Prevents concurrent processing of events using a flag.
   */
  start(): void {
    if (this.daemonTimer) {
      // Already running, so exit.
      return
    }
    // Set up a timer that triggers at regular intervals.
    this.daemonTimer = setInterval(async () => {
      // Check if processing is already underway.
      if (!this.isProcessing) {
        // Mark as processing.
        this.isProcessing = true
        try {
          // Process events in the queue.
          await this.processQueue()
        } catch (error) {
          // Log and handle any errors during processing.
          logger.error('Error processing queue:', error)
        } finally {
          // Reset processing flag, allowing the next interval to process.
          this.isProcessing = false
        }
      }
    }, this.daemonInterval)
  }

  /**
   * Stop the event interleaving process.
   * Clears the timer and resets the related state.
   */
  stop(): void {
    if (this.daemonTimer) {
      // Clear the interval timer.
      clearInterval(this.daemonTimer)
      this.daemonTimer = null
    }
  }

  /**
   * Handle an incoming event.
   * Adds the event to the priority queue and sorts it to maintain time order.
   * @param event - The event to be handled.
   */
  onEvent(event: Event): Promise<void> {
    // Add event to the queue with the current timestamp.
    this.priorityQueue.push({ event, receivedAt: new Date() })
    // Sort the queue to ensure time ordering.
    this.priorityQueue.sort((a: ReceivedEvent, b: ReceivedEvent) => compareEvents(a.event, b.event))
    return Promise.resolve()
  }

  /**
   * Process the event queue.
   * Dequeues and propagates events that are ready based on the propagation delay.
   */
  private async processQueue(): Promise<void> {
    logger.info(`Processing queue with ${this.priorityQueue.length} event${this.priorityQueue.length === 1 ? '' : 's'}`)
    const now = new Date()
    while (this.priorityQueue.length > 0) {
      const receivedEvent = this.priorityQueue[0] as ReceivedEvent
      const elapsedWaitTime = now.getTime() - receivedEvent.receivedAt.getTime()
      // Check if the event has waited long enough based on the propagation delay.
      if (elapsedWaitTime < this.propagationDelay) {
        // If not ready, exit the loop to wait more.
        break
      }
      // Process the event for each subscriber.
      for (const subscriber of this.subscribers) {
        await subscriber.onEvent(receivedEvent.event)
      }
      // Remove the processed event from the queue.
      this.priorityQueue.shift()
    }
  }
}
