#!/usr/bin/env bun

import { env } from '#/env'
import { logger } from '#/logger'
import { extractChain } from 'viem'
import { evmClients } from '#/clients'
import { watchAllEfpContractEvents } from '#/watch'
import { asyncExitHook, gracefulExit } from 'exit-hook'
asyncExitHook(
  async signal => {
    logger.warn(`Exiting with signal ${signal}`)
  },
  { wait: 1_000 }
)

main().catch(error => {
  logger.error(error)
  gracefulExit(1)
})

async function main() {
  const chainId = env.CHAIN_ID
  logger.success(`Starting indexer with chain id ${chainId}…`)
  const client = evmClients['31337']()
  try {
    await watchAllEfpContractEvents({ client })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(errorMessage)
  }
}
