import { http, createPublicClient, fallback, walletActions, webSocket } from 'viem'
import { base, mainnet, optimism } from 'viem/chains'
import { env } from '#/env.ts'

export const evmClients = {
  '1': () =>
    createPublicClient({
      key: 'mainnet-client',
      name: 'Mainnet Client',
      chain: mainnet,
      transport: fallback([http(env.PRIMARY_RPC_ETH), http(env.SECONDARY_RPC_ETH)], {
        rank: false
      }),
      batch: { multicall: true }
    }).extend(walletActions),
  '10': () =>
    createPublicClient({
      key: 'optimism-client',
      name: 'Optimism Client',
      chain: optimism,
      transport: fallback([http(env.PRIMARY_RPC_OP), http(env.SECONDARY_RPC_OP)], { rank: false }),
      batch: { multicall: true }
    }).extend(walletActions),
  '8453': () =>
    createPublicClient({
      key: 'base-client',
      name: 'Base Client',
      chain: base,
      transport: fallback([http(env.PRIMARY_RPC_BASE), http(env.SECONDARY_RPC_BASE)], { rank: false })
    }).extend(walletActions)
}

export type EvmClient = ReturnType<(typeof evmClients)[typeof env.CHAIN_ID]>
