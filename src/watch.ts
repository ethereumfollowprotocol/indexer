import { decodeEventLog, type PublicClient, type TestClient } from 'viem'
import {
  EFPListMinterABI,
  EFPListRecordsABI,
  EFPListRegistryABI,
  EFPListMetadataABI,
  EFPAccountMetadataABI
} from '#/abi'
import { env } from '#/env'
import { logger } from '#/logger'

export async function watchAllEfpContractEvents({ client }: { client: PublicClient }) {
  logger.info('Watching EFP contract events...')
  client.watchContractEvent({
    abi: EFPAccountMetadataABI,
    address: env.EFP_CONTRACTS.LIST_RECORDS,
    onError: error => {
      console.log('EFPAccountMetadataABI error:', error)
    },
    onLogs: logs => {
      console.log('\n--- EFPAccountMetadata ---\n')
      logs.map(({ data, topics }) => {
        const _topics = decodeEventLog({
          abi: EFPAccountMetadataABI,
          data,
          topics
        })
        console.log('[EFPAccountMetadata] Decoded topics:', JSON.stringify(_topics, undefined, 2))
      })
    }
  })

  client.watchContractEvent({
    abi: EFPListRegistryABI,
    address: env.EFP_CONTRACTS.LIST_REGISTRY,
    onError: error => {
      console.log('EFPListRegistryABI error:', error)
    },
    onLogs: logs => {
      console.log('\n--- EFPListRegistry ---\n')
      logs.map(({ data, topics }) => {
        const _topics = decodeEventLog({
          abi: EFPListRegistryABI,
          data,
          topics
        })
        console.log('[EFPListRegistry] Decoded topics:', JSON.stringify(_topics, undefined, 2))
      })
    }
  })

  client.watchContractEvent({
    abi: EFPListMetadataABI,
    address: env.EFP_CONTRACTS.LIST_METADATA,
    onError: error => {
      console.log('EFPListMetadataABI error:', error)
    },
    onLogs: logs => {
      console.log('\n--- EFPListMetadata ---\n')
      logs.map(({ data, topics }) => {
        const _topics = decodeEventLog({
          abi: EFPListMetadataABI,
          data,
          topics
        })
        console.log('[EFPListMetadata] Decoded topics:', JSON.stringify(_topics, undefined, 2))
      })
    }
  })

  client.watchContractEvent({
    abi: EFPListRecordsABI,
    address: env.EFP_CONTRACTS.LIST_RECORDS,
    onError: error => {
      logger.error('EFPListRecordsABI error:', error)
    },
    onLogs: logs => {
      logger.info('\n--- EFPListRecords ---\n')
      logs.map(({ data, topics }) => {
        const _topics = decodeEventLog({
          abi: EFPListRecordsABI,
          data,
          topics
        })
        logger.info('[EFPListRecords] Decoded topics:', JSON.stringify(_topics, undefined, 2))
      })
    }
  })

  client.watchContractEvent({
    abi: EFPListMinterABI,
    address: env.EFP_CONTRACTS.LIST_MINTER,
    onError: error => {
      console.log('EFPListMinterABI error:', error)
    },
    onLogs: logs => {
      console.log('\n--- EFPListMinter ---\n')
      logs.map(({ data, topics }) => {
        const _topics = decodeEventLog({
          abi: EFPListMinterABI,
          data,
          topics
        })
        console.log('[EFPListMinter] Decoded topics:', JSON.stringify(_topics, undefined, 2))
      })
    }
  })
}