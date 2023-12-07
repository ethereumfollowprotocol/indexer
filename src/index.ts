#!/usr/bin/env bun
import { env } from '#/env'
import { logger } from '#/logger'
import { evmClients } from '#/clients'
import { pingRpc } from '#/utilities/ping'
import { watchAllEfpContractEvents } from '#/watch'
import { asyncExitHook, gracefulExit } from 'exit-hook'

main()

asyncExitHook(
  async signal => {
    logger.warn(`Exiting with signal ${signal}`)
  },
  { wait: 1_000 }
)

async function main() {
  try {
    const chainId = env.CHAIN_ID
    const client = evmClients[chainId]()
    await pingRpc({ client })
    logger.box(`Starting indexer with chain id ${chainId}`, '🔍')
    await watchAllEfpContractEvents({ client })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.fatal(errorMessage)
    gracefulExit(1)
  }
}
