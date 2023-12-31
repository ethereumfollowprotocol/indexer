import type { Event } from '#/pubsub/event'

/**
 * Interface defining the structure and methods for an EventSubscriber.
 */
export interface EventSubscriber {
  onEvent(event: Event): Promise<void>
  onEvents(events: Event[]): Promise<void>
}
