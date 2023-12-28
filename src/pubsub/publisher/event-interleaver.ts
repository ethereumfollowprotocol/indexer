import { logger } from '#/logger'
import type { EventSubscriber } from '../subscriber'
import type { EventPublisher } from './interface'

import { type Event, compareEvents } from '#/pubsub/event'

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
  private readonly propagationDelay: number = 3000

  // Interval at which the queue is checked and processed.
  private readonly daemonInterval: number = 1000

  // Timer for the repeating process. Null when not running.
  private daemonTimer: NodeJS.Timeout | null = null

  // Flag to prevent concurrent processing.
  private isProcessing = false

  constructor(upstream: EventPublisher[] = []) {
    for (const publisher of upstream) {
      publisher.subscribe(this)
    }
  }

  /**
   * Subscribe a new event subscriber.
   * @param subscriber - The subscriber to be added.
   */
  subscribe(subscriber: EventSubscriber): EventPublisher {
    this.subscribers.push(subscriber)
    return this
  }

  /**
   * Unsubscribe an existing event subscriber.
   * @param subscriber - The subscriber to be removed.
   */
  unsubscribe(subscriber: EventSubscriber): EventPublisher {
    this.subscribers = this.subscribers.filter(existingSubscriber => existingSubscriber !== subscriber)
    return this
  }

  /**
   * Start the event interleaving process.
   * Initializes and starts a timer to process the event queue at regular intervals.
   * Prevents concurrent processing of events using a flag.
   */
  start(): Promise<void> {
    if (this.daemonTimer) {
      // Already running, so exit.
      return Promise.resolve()
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
    return Promise.resolve()
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
