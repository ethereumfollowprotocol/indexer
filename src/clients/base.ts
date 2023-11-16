import { http, fallback, createPublicClient, createClient } from 'viem'
import { mainnet, optimism, sepolia, optimismSepolia } from 'viem/chains'

import { env } from '#/env.ts'

export const evmClients = {
  mainnet: createClient({
    key: 'mainnet-client',
    name: 'Mainnet Client',
    chain: mainnet,
    transport: fallback(
      [
        http(`https://rpc.ankr.com/eth/${env.ANKR_ID}`),
        http(`https://mainnet.infura.io/v3/${env.INFURA_ID}`),
        http(`https://eth.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`),
        http(`https://eth-mainnet.g.alchemy.com/v2/${env.ALCHEMY_ID}`)
      ],
      { rank: true }
    ),
    batch: { multicall: true }
  }),
  optimism: createPublicClient({
    key: 'optimism-client',
    name: 'Optimism Client',
    chain: optimism,
    transport: fallback(
      [
        http(`https://rpc.ankr.com/optimism/${env.ANKR_ID}`),
        http(`https://opt-mainnet.g.alchemy.com/v2/${env.ALCHEMY_ID}`),
        http(`https://optimism-mainnet.infura.io/v3/${env.INFURA_ID}`),
        http(`https://optimism.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`)
      ],
      { rank: true }
    ),
    batch: { multicall: true }
  }),
  optimismSepolia: createPublicClient({
    key: 'op-sepolia-client',
    name: 'OP Sepolia Client',
    chain: optimismSepolia,
    transport: fallback(
      [
        http('https://sepolia.optimism.io'),
        http('https://sepolia-rollup.arbitrum.io/rpc'),
        http(`https://optimism-sepolia.infura.io/v3/${env.INFURA_ID}`)
      ],
      { rank: true }
    ),
    batch: { multicall: true }
  }),
  sepolia: createPublicClient({
    key: 'sepolia-client',
    name: 'Sepolia Client',
    chain: sepolia,
    transport: fallback(
      [
        http(`https://sepolia.infura.io/v3/${env.INFURA_ID}`),
        http(`https://rpc.ankr.com/eth_sepolia/${env.ANKR_ID}`),
        http(`https://eth-sepolia.g.alchemy.com/v2/${env.ALCHEMY_ID}`)
      ],
      { rank: true }
    ),
    batch: { multicall: true }
  })
}
