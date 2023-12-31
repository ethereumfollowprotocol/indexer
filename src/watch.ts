import { asyncExitHook } from 'exit-hook'
import { efpAccountMetadataAbi, efpListMinterAbi, efpListRecordsAbi, efpListRegistryAbi } from '#/abi'
import type { EvmClient } from '#/clients'
import { env } from '#/env'
import { logger } from '#/logger'
import { ContractEventPublisher } from '#/pubsub/publisher/contract-event-publisher'
import { EventInterleaver } from '#/pubsub/publisher/event-interleaver'
import type { EventPublisher } from '#/pubsub/publisher/interface'
import { EventUploader } from '#/pubsub/subscriber/event-uploader'
import { raise, sleep } from '#/utilities'

export async function watchAllEfpContractEvents({ client }: { client: EvmClient }) {
  try {
    const chainId: bigint = BigInt(await client.getChainId())

    // 1. Listen to all EFP contracts for events
    const publishers: EventPublisher[] = [
      new ContractEventPublisher(
        client,
        chainId,
        'EFPAccountMetadata',
        efpAccountMetadataAbi,
        env.EFP_CONTRACTS.ACCOUNT_METADATA
      ),
      new ContractEventPublisher(
        client,
        chainId,
        'EFPListRegistry',
        efpListRegistryAbi,
        env.EFP_CONTRACTS.LIST_REGISTRY
      ),
      new ContractEventPublisher(client, chainId, 'EFPListRecords', efpListRecordsAbi, env.EFP_CONTRACTS.LIST_RECORDS),
      new ContractEventPublisher(client, chainId, 'EFPListMinter', efpListMinterAbi, env.EFP_CONTRACTS.LIST_MINTER)
    ]

    // 2. Collect and interleave events in to a single ordered steam
    const eventInterleaver = new EventInterleaver(publishers)
    publishers.push(eventInterleaver)

    // 3. Upload events to the database
    eventInterleaver.subscribe(new EventUploader())

    // Start all publishers
    await Promise.all(publishers.map(publisher => publisher.start()))

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
