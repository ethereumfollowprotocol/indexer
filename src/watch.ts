import { env } from '#/env'
import { type PublicClient } from 'viem'
import {
  EFPAccountMetadataPublisher,
  EFPListMetadataPublisher,
  EFPListMinterPublisher,
  EFPListRecordsPublisher,
  EFPListRegistryPublisher
} from './pubsub/publishers'
import {
  EFPAccountMetadataSubscriber,
  EFPListMetadataSubscriber,
  EFPListMinterSubscriber,
  EFPListRecordsSubscriber,
  EFPListRegistrySubscriber
} from './pubsub/subscribers'

export async function watchAllEfpContractEvents({ client }: { client: PublicClient }) {
  const efpAccountMetadataPublisher = new EFPAccountMetadataPublisher(
    client,
    env.EFP_CONTRACTS.ACCOUNT_METADATA
  )
  const efpListMetadataPublisher = new EFPListMetadataPublisher(
    client,
    env.EFP_CONTRACTS.LIST_METADATA
  )
  const efpListRegistryPublisher = new EFPListRegistryPublisher(
    client,
    env.EFP_CONTRACTS.LIST_REGISTRY
  )
  const efpListRecordsPublisher = new EFPListRecordsPublisher(
    client,
    env.EFP_CONTRACTS.LIST_RECORDS
  )
  const efpListMinterPublisher = new EFPListMinterPublisher(client, env.EFP_CONTRACTS.LIST_MINTER)

  const efpAccountMetadataSubscriber = new EFPAccountMetadataSubscriber(
    env.EFP_CONTRACTS.ACCOUNT_METADATA
  )
  const efpListMetadataSubscriber = new EFPListMetadataSubscriber(env.EFP_CONTRACTS.LIST_METADATA)
  const efpListRegistrySubscriber = new EFPListRegistrySubscriber(env.EFP_CONTRACTS.LIST_REGISTRY)
  const efpListRecordsSubscriber = new EFPListRecordsSubscriber(env.EFP_CONTRACTS.LIST_RECORDS)
  const efpListMinterSubscriber = new EFPListMinterSubscriber(env.EFP_CONTRACTS.LIST_MINTER)

  efpAccountMetadataPublisher.subscribe(efpAccountMetadataSubscriber)
  efpListMetadataPublisher.subscribe(efpListMetadataSubscriber)
  efpListRegistryPublisher.subscribe(efpListRegistrySubscriber)
  efpListRecordsPublisher.subscribe(efpListRecordsSubscriber)
  efpListMinterPublisher.subscribe(efpListMinterSubscriber)

  efpAccountMetadataPublisher.start()
  efpListMetadataPublisher.start()
  efpListRegistryPublisher.start()
  efpListRecordsPublisher.start()
  efpListMinterPublisher.start()
}
