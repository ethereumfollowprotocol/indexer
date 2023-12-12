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
  DatabaseUploader,
  EFPAccountMetadataSubscriber,
  EFPListMinterSubscriber,
  EFPListRecordsSubscriber,
  EFPListRegistrySubscriber,
  type EventSubscriber
} from '#/pubsub/subscribers'
import { raise } from '#/utilities'

export async function watchAllEfpContractEvents({ client }: { client: EvmClient }) {
  try {
    const efpAccountMetadataPublisher = new EFPAccountMetadataPublisher(client, env.EFP_CONTRACTS.ACCOUNT_METADATA)
    const efpListRegistryPublisher = new EFPListRegistryPublisher(client, env.EFP_CONTRACTS.LIST_REGISTRY)
    const efpListRecordsPublisher = new EFPListRecordsPublisher(client, env.EFP_CONTRACTS.LIST_RECORDS)
    const efpListMinterPublisher = new EFPListMinterPublisher(client, env.EFP_CONTRACTS.LIST_MINTER)

    const efpAccountMetadataSubscriber = new EFPAccountMetadataSubscriber(env.EFP_CONTRACTS.ACCOUNT_METADATA)
    const efpListRegistrySubscriber = new EFPListRegistrySubscriber(env.EFP_CONTRACTS.LIST_REGISTRY)
    const efpListRecordsSubscriber = new EFPListRecordsSubscriber(env.EFP_CONTRACTS.LIST_RECORDS)
    const efpListMinterSubscriber = new EFPListMinterSubscriber(env.EFP_CONTRACTS.LIST_MINTER)

    efpAccountMetadataPublisher.subscribe(efpAccountMetadataSubscriber)
    efpListRegistryPublisher.subscribe(efpListRegistrySubscriber)
    efpListRecordsPublisher.subscribe(efpListRecordsSubscriber)
    efpListMinterPublisher.subscribe(efpListMinterSubscriber)

    const dbUploader: EventSubscriber = new DatabaseUploader()
    efpAccountMetadataPublisher.subscribe(dbUploader)
    efpListRegistryPublisher.subscribe(dbUploader)
    efpListRecordsPublisher.subscribe(dbUploader)
    efpListMinterPublisher.subscribe(dbUploader)

    efpAccountMetadataPublisher.start()
    efpListRegistryPublisher.start()
    efpListRecordsPublisher.start()
    efpListMinterPublisher.start()

    logger.log('Watching EFP contracts for events...')
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(watchAllEfpContractEvents.name, errorMessage)
    raise(error)
  }
}
