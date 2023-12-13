#!/usr/bin/env bun
import { evmClients, type EvmClient } from '#/clients'
import { env } from '#/env'
import { logger } from '#/logger'
import { pingRpc } from '#/utilities/ping'
import { watchAllEfpContractEvents } from '#/watch'
import { gracefulExit } from 'exit-hook'

const GREEN = '\x1b[32m'
const YELLOW = '\x1b[33m'
const ENDC = '\x1b[0m'

async function waitForPingSuccess(client: EvmClient): Promise<void> {
  async function tryAttempt(attempt: number): Promise<void> {
    try {
      await pingRpc({ client })
      console.log(`${GREEN}Successfully connected to RPC${ENDC}`)
    } catch (error) {
      logger.warn(`${YELLOW}(Attempt: ${attempt}) Failed to connect to RPC${ENDC}`, error)
      await new Promise(resolve => setTimeout(resolve, 1_000))
      await tryAttempt(attempt + 1)
    }
  }
  await tryAttempt(1)
}

async function main() {
  try {
    logger.log(`Process ID: ${process.pid}`)
    const chainId = env.CHAIN_ID
    const client = evmClients[chainId]()
    await waitForPingSuccess(client)
    logger.box(`EFP Indexer start`, '🔍')
    logger.log(`chain id ${chainId}`)
    await watchAllEfpContractEvents({ client })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : error
    logger.fatal(errorMessage)
    gracefulExit(1)
  }
  logger.log('end')
}

main()
