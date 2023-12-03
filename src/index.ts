#!/usr/bin/env bun

import { env } from '#/env'
import { evmClients } from '#/clients'
import { logger } from '#/logger'
import { watchAllEfpContractEvents } from '#/watch'
import { asyncExitHook, gracefulExit } from 'exit-hook'

asyncExitHook(
  async signal => {
    logger.warn(`Exiting with signal ${signal}`)
  },
  { wait: 2_000 }
)

main().catch(error => {
  logger.error(error)
  gracefulExit(1)
})

async function main() {
  logger.success('Starting indexer…')
  const client = evmClients['31337']()
  try {
    // @ts-expect-error
    await watchAllEfpContractEvents({ client: client })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.error(errorMessage)
  }
}
