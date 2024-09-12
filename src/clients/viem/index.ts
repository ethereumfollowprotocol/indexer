import { http, createPublicClient, createTestClient, fallback, publicActions, walletActions, webSocket } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { base, baseSepolia, foundry, mainnet, optimism, optimismSepolia, sepolia } from 'viem/chains'
import { env } from '#/env.ts'

export const evmClients = {
  '31337': () =>
    createTestClient({
      chain: foundry,
      mode: 'anvil',
      transport: http(env.ETHEREUM_LOCAL_NODE_URL),
      account: privateKeyToAccount(
        env.ANVIL_ACCOUNT_PRIVATE_KEY || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
      )
    })
      .extend(publicActions)
      .extend(walletActions),
  '1': () =>
    createPublicClient({
      key: 'mainnet-client',
      name: 'Mainnet Client',
      chain: mainnet,
      transport: fallback(
        [
          //   http(`https://rpc.ankr.com/eth/${env.ANKR_ID}`),
          //   http(`https://ethereum.ethfollow.xyz/v1/mainnet`),
          http(`https://eth-mainnet.g.alchemy.com/v2/${env.MAINNET_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://mainnet.infura.io/v3/${env.INFURA_ID}`),
          http(`https://eth.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`),
          webSocket(`wss://eth-mainnet.g.alchemy.com/v2/${env.MAINNET_ALCHEMY_ID}`),
          webSocket(`wss://eth.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`),
          webSocket(`wss://mainnet.infura.io/ws/v3/${env.INFURA_ID}`)
        ],
        {
          /**
           * TODO: investigate why public actions hang when rank is enabled
           * @link https://discord.com/channels/1156791276818157609/1156791519089541241/1178111399839399937
           */
          rank: false
        }
      ),
      batch: { multicall: true }
    }).extend(walletActions),
  '10': () =>
    createPublicClient({
      key: 'optimism-client',
      name: 'Optimism Client',
      chain: optimism,
      transport: fallback(
        [
          //   http(`https://rpc.ankr.com/optimism/${env.ANKR_ID}`),
          http(`https://opt-mainnet.g.alchemy.com/v2/${env.OPTIMISM_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.optimism.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://optimism-mainnet.infura.io/v3/${env.INFURA_ID}`),
          http(`https://optimism.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`),
          webSocket(`wss://opt-mainnet.g.alchemy.com/v2/${env.OPTIMISM_ALCHEMY_ID}`),
          webSocket(`wss://optimism.llamarpc.com/rpc/${env.LLAMAFOLIO_ID}`)
        ],
        { rank: false }
      ),
      batch: { multicall: true }
    }).extend(walletActions),
  '8453': () =>
    createPublicClient({
      key: 'base-client',
      name: 'Base Client',
      chain: base,
      transport: fallback(
        [
          http(`https://base-mainnet.g.alchemy.com/v2/${env.BASE_SEPOLIA_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.base-mainnet.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://sepolia.base.org`)
        ],
        { rank: false }
      ),
      batch: { multicall: true }
    }).extend(walletActions),
  '11155111': () =>
    createPublicClient({
      key: 'sepolia-client',
      name: 'Sepolia Client',
      chain: sepolia,
      transport: fallback(
        [
          http(`https://eth-sepolia.g.alchemy.com/v2/${env.SEPOLIA_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.ethereum-sepolia.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://rpc.ankr.com/eth_sepolia/${env.ANKR_ID}`),
          http(`https://sepolia.infura.io/v3/${env.INFURA_ID}`),
          webSocket(`wss://sepolia.infura.io/ws/v3/${env.INFURA_ID}`),
          webSocket(`wss://eth-sepolia.g.alchemy.com/v2/${env.SEPOLIA_ALCHEMY_ID}`)
        ],
        { rank: false }
      ),
      batch: { multicall: true }
    }).extend(walletActions),
  '11155420': () =>
    createPublicClient({
      key: 'op-sepolia-client',
      name: 'OP Sepolia Client',
      chain: optimismSepolia,
      transport: fallback(
        [
          http(`https://opt-sepolia.g.alchemy.com/v2/${env.OP_SEPOLIA_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.optimism-sepolia.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://optimism-sepolia.infura.io/v3/${env.INFURA_ID}`),
          http('https://sepolia.optimism.io'),
          http('https://sepolia-rollup.arbitrum.io/rpc')
        ],
        { rank: false }
      ),
      batch: { multicall: true }
    }).extend(walletActions),
  '84532': () =>
    createPublicClient({
      key: 'base-sepolia-client',
      name: 'Base Sepolia Client',
      chain: baseSepolia,
      transport: fallback(
        [
          http(`https://base-sepolia.g.alchemy.com/v2/${env.BASE_SEPOLIA_ALCHEMY_ID}`),
          http(`https://${env.QUIKNODE_PREFIX}.base-sepolia.quiknode.pro/${env.QUIKNODE_ID}`),
          http(`https://sepolia.base.org`)
        ],
        { rank: false }
      ),
      batch: { multicall: true }
    }).extend(walletActions)
}

export type EvmClient = ReturnType<(typeof evmClients)[typeof env.CHAIN_ID]>
