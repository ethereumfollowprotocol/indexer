import type { EvmClient } from '#/clients'
import { logger } from '#/logger'
import { raise } from '#/utilities'

/**
 * Ping rpc url before starting indexer process
 * Exit if rpc url is not available
 */
export async function pingRpc({ client }: { client: EvmClient }) {
  try {
    await client.transport.request({ method: 'eth_blockNumber', params: [] })
  } catch (error) {
    raise(
      `\nUnable to ping rpc url for [${client.name} - ${client.key} - ${client.transport.name}] \n${
        error instanceof Error ? error.message : error
      }`
    )
  }
}
