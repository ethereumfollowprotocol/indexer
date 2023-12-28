#!/usr/bin/env bun
import { type ChildProcessWithoutNullStreams, spawn } from 'node:child_process'
import { gracefulExit } from 'exit-hook'
import { type EvmClient, evmClients } from '#/clients'
import { env } from '#/env'
import { logger } from '#/logger'
import { sleep } from '#/utilities'
import { colors } from '#/utilities/colors'
import { pingRpc } from '#/utilities/ping'
import { watchAllEfpContractEvents } from '#/watch'

async function waitForPingSuccess(client: EvmClient): Promise<void> {
  async function tryAttempt(attempt: number): Promise<void> {
    try {
      await pingRpc({ client })
      console.log(`${colors.GREEN}Successfully connected to RPC${colors.ENDC}`)
    } catch (error) {
      logger.warn(`${colors.YELLOW}(Attempt: ${attempt}) Failed to connect to RPC${colors.ENDC}`, error)
      await sleep(1_000)
      await tryAttempt(attempt + 1)
    }
  }
  await tryAttempt(1)
}

async function runDbmateCommand(command: string): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (reason?: any) => void) => {
    const cmd = 'bunx'
    const args = ['dbmate', command]
    const cmdWithArgs: string = [cmd, ...args].join(' ')
    const dbmate: ChildProcessWithoutNullStreams = spawn(cmd, args)

    dbmate.stdout.on('data', (data: Buffer) => {
      console.log(data.toString())
    })

    dbmate.stderr.on('data', (data: Buffer) => {
      console.error(data.toString())
    })

    dbmate.on('close', (code: number) => {
      if (code === 0) {
        resolve()
        console.log(`${cmdWithArgs} process exited with code ${code}`)
      } else {
        reject(new Error(`${cmdWithArgs} process exited with code ${code}`))
      }
    })
  })
}

async function main() {
  try {
    logger.log(`Process ID: ${process.pid}`)
    // wait for db to be up
    for (;;) {
      try {
        logger.log(`dbmate up`, `🗄️`)
        await runDbmateCommand('status')
        break
      } catch {
        // logger.warn(error)
        await sleep(1_000)
      }
    }
    logger.box(`🗄️`, `dbmate up`)
    await runDbmateCommand('up')
    logger.box(`🗄️`, `dbmate status`)
    await runDbmateCommand('status')

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
