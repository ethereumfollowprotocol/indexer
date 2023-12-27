import type { EvmClient } from '#/clients'
import { env } from '#/env'
import { logger } from '#/logger'
import {
  EFPAccountMetadataPublisher,
  EFPListMinterPublisher,
  EFPListRecordsPublisher,
  EFPListRegistryPublisher,
  EventInterleaver,
  type EventPublisher
} from '#/pubsub/publisher/publishers'
import { EventDispatcher as EventProcessor, EventsTableUploader, type EventSubscriber } from '#/pubsub/subscribers'
import { raise, sleep } from '#/utilities'
import { asyncExitHook } from 'exit-hook'

export async function watchAllEfpContractEvents({ client }: { client: EvmClient }) {
  try {
    const chainId: bigint = BigInt(await client.getChainId())
    const efpAccountMetadataPublisher: EventPublisher = new EFPAccountMetadataPublisher(
      client,
      chainId,
      env.EFP_CONTRACTS.ACCOUNT_METADATA
    )
    const efpListRegistryPublisher: EventPublisher = new EFPListRegistryPublisher(
      client,
      chainId,
      env.EFP_CONTRACTS.LIST_REGISTRY
    )
    const efpListRecordsPublisher: EventPublisher = new EFPListRecordsPublisher(
      client,
      chainId,
      env.EFP_CONTRACTS.LIST_RECORDS
    )
    const efpListMinterPublisher: EventPublisher = new EFPListMinterPublisher(
      client,
      chainId,
      env.EFP_CONTRACTS.LIST_MINTER
    )
    const eventInterleaver = new EventInterleaver()
    efpAccountMetadataPublisher.subscribe(eventInterleaver)
    efpListRegistryPublisher.subscribe(eventInterleaver)
    efpListRecordsPublisher.subscribe(eventInterleaver)
    efpListMinterPublisher.subscribe(eventInterleaver)

    const eventsTableUploader: EventSubscriber = new EventsTableUploader()
    eventInterleaver.subscribe(eventsTableUploader)

    const eventProcessor: EventSubscriber = new EventProcessor()
    eventInterleaver.subscribe(eventProcessor)

    const publishers: EventPublisher[] = [
      efpAccountMetadataPublisher,
      efpListRegistryPublisher,
      efpListRecordsPublisher,
      efpListMinterPublisher,
      eventInterleaver
    ]

    // Start all publishers
    for (const publisher of publishers) {
      await publisher.start()
    }

    asyncExitHook(
      signal => {
        logger.log(`Exiting with signal ${signal}`)
        logger.log(`begin publisher shutdown`)
        for (const publisher of publishers) {
          publisher.stop()
        }
        logger.log(`end publisher shutdown`)
        logger.log(`exit`)
      },
      { wait: 500 }
    )

    logger.log('Watching EFP contracts for events...')
    for (;;) {
      logger.info('Waiting for events...')
      await sleep(1_000)
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(watchAllEfpContractEvents.name, errorMessage)
    raise(error)
  }
}
