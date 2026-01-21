import { asyncExitHook } from 'exit-hook'
import { env } from '#/env'
import { logger } from '#/logger'
import { ContractEventPublisher } from '#/pubsub/publisher/contract-event-publisher'
import { EventInterleaver } from '#/pubsub/publisher/event-interleaver'
import type { EventPublisher } from '#/pubsub/publisher/interface'
import { EventUploader } from '#/pubsub/subscriber/event-uploader'
import { raise, sleep } from '#/utilities'
import { efpAccountMetadataAbi, efpListMinterAbi, efpListRecordsAbi, efpListRegistryAbi } from './abi/generated/index'
import type { EvmClient } from './clients/viem/index'

export async function watchAllEfpContractEvents({ client }: { client: EvmClient }) {

  if (env.HEARTBEAT_URL && env.HEARTBEAT_URL !== 'unset') {
    try {
      const response = await fetch(`${env.HEARTBEAT_URL}`)
      const text = await response.text()
      logger.info(`Heartbeat registered`)
    } catch (err) {
        logger.info(`Failed to register heartbeat `)
    }
  }
  
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
      new ContractEventPublisher(
        client,
        chainId,
        'EFPListRecordsV2',
        efpListRecordsAbi,
        env.EFP_CONTRACTS.LIST_RECORDS_V2
      )
    ]

    // 2. Collect and interleave events in to a single ordered steam
    const eventInterleaver = new EventInterleaver(publishers)
    publishers.push(eventInterleaver)

    // 3. Upload events to the database
    eventInterleaver.subscribe(new EventUploader())

    // Start publishers
    await eventInterleaver.start()
    logger.log('Started EventInterleaver publisher')

    if (env.RECORDS_ONLY === 'true') {
      await Promise.all([publishers[2], publishers[3]].map(publisher => publisher?.start()))
      logger.log('Started in ListRecords only mode')
    } else {
      await Promise.all(
        [publishers[0], publishers[1], publishers[2], publishers[3]].map(publisher => publisher?.start())
      )
      logger.log('Started in All Events mode')
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
    let heartbeat = 0
    for (;;) {
      logger.info('Waiting for events...')
      await sleep(1_000)
      heartbeat++
      if (heartbeat > 300 && env.HEARTBEAT_URL && env.HEARTBEAT_URL !== 'unset') {
        // call snitch
        try {
          const response = await fetch(`${env.HEARTBEAT_URL}`)
          const text = await response.text()
          logger.info(`Heartbeat registered`)
          heartbeat = 0
        } catch (err) {
          logger.info(`Failed to register heartbeat `)
        }
      }
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(watchAllEfpContractEvents.name, errorMessage)
    raise(error)
  }
}
