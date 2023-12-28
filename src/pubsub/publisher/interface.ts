import type { EventSubscriber } from '../subscriber'

/**
 * Interface defining the structure and methods for an EventPublisher.
 */
export interface EventPublisher {
  subscribe(subscriber: EventSubscriber): void
  unsubscribe(subscriber: EventSubscriber): void
  start(): Promise<void>
  stop(): void
}
