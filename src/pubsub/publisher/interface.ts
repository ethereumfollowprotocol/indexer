import type { EventSubscriber } from '#/pubsub/subscriber/interface'

/**
 * Interface defining the structure and methods for an EventPublisher.
 */
export interface EventPublisher {
  subscribe(subscriber: EventSubscriber): EventPublisher
  unsubscribe(subscriber: EventSubscriber): EventPublisher
  start(): Promise<void>
  stop(): void
}
