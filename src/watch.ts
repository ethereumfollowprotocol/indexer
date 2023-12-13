import type { EvmClient } from '#/clients'
import { env } from '#/env'
import { logger } from '#/logger'
import {
  EFPAccountMetadataPublisher,
  EFPListMinterPublisher,
  EFPListRecordsPublisher,
  EFPListRegistryPublisher
} from '#/pubsub/publishers'
import {
  EFPAccountMetadataSubscriber,
  EFPListMinterSubscriber,
  EFPListRecordsSubscriber,
  EFPListRegistrySubscriber,
  EventDispatcher as EventProcessor,
  EventsTableUploader,
  type EventSubscriber
} from '#/pubsub/subscribers'
import { raise } from '#/utilities'
import { asyncExitHook } from 'exit-hook'

export async function watchAllEfpContractEvents({ client }: { client: EvmClient }) {
  try {
    const chainId: bigint = BigInt(await client.getChainId())
    const efpAccountMetadataPublisher = new EFPAccountMetadataPublisher(
      client,
      chainId,
      env.EFP_CONTRACTS.ACCOUNT_METADATA
    )
    const efpListRegistryPublisher = new EFPListRegistryPublisher(client, chainId, env.EFP_CONTRACTS.LIST_REGISTRY)
    const efpListRecordsPublisher = new EFPListRecordsPublisher(client, chainId, env.EFP_CONTRACTS.LIST_RECORDS)
    const efpListMinterPublisher = new EFPListMinterPublisher(client, chainId, env.EFP_CONTRACTS.LIST_MINTER)

    const efpAccountMetadataSubscriber = new EFPAccountMetadataSubscriber(env.EFP_CONTRACTS.ACCOUNT_METADATA)
    const efpListRegistrySubscriber = new EFPListRegistrySubscriber(env.EFP_CONTRACTS.LIST_REGISTRY)
    const efpListRecordsSubscriber = new EFPListRecordsSubscriber(env.EFP_CONTRACTS.LIST_RECORDS)
    const efpListMinterSubscriber = new EFPListMinterSubscriber(env.EFP_CONTRACTS.LIST_MINTER)

    efpAccountMetadataPublisher.subscribe(efpAccountMetadataSubscriber)
    efpListRegistryPublisher.subscribe(efpListRegistrySubscriber)
    efpListRecordsPublisher.subscribe(efpListRecordsSubscriber)
    efpListMinterPublisher.subscribe(efpListMinterSubscriber)

    const eventsTableUploader: EventSubscriber = new EventsTableUploader()
    efpAccountMetadataPublisher.subscribe(eventsTableUploader)
    efpListRegistryPublisher.subscribe(eventsTableUploader)
    efpListRecordsPublisher.subscribe(eventsTableUploader)
    efpListMinterPublisher.subscribe(eventsTableUploader)

    const eventProcessor: EventSubscriber = new EventProcessor()
    efpAccountMetadataPublisher.subscribe(eventProcessor)
    efpListRegistryPublisher.subscribe(eventProcessor)
    efpListRecordsPublisher.subscribe(eventProcessor)
    efpListMinterPublisher.subscribe(eventProcessor)

    const publishers = [
      efpAccountMetadataPublisher,
      efpListRegistryPublisher,
      efpListRecordsPublisher,
      efpListMinterPublisher
    ]

    // Start all publishers
    for (const publisher of publishers) {
      publisher.start()
    }

    asyncExitHook(
      // biome-ignore lint/nursery/useAwait: <explanation>
      async signal => {
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
    while (true) {
      logger.log('Waiting for events...')
      await new Promise(resolve => setTimeout(resolve, 1_000))
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(watchAllEfpContractEvents.name, errorMessage)
    raise(error)
  }
}
