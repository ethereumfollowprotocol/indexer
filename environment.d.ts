interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly CHAIN_ID: '1' | '10' | '31337' | '11155111' | '11155420' | '84532'
  readonly ANKR_ID: string
  readonly INFURA_ID: string
  readonly LLAMAFOLIO_ID: string
  readonly MAINNET_ALCHEMY_ID: string
  readonly OPTIMISM_ALCHEMY_ID: string
  readonly SEPOLIA_ALCHEMY_ID: string
  readonly BASE_SEPOLIA_ALCHEMY_ID: string
  readonly OP_SEPOLIA_ALCHEMY_ID: string
  readonly ETHEREUM_LOCAL_NODE_URL: string
  readonly DATABASE_URL: string
  readonly ENABLE_DATABASE_LOGGING: string
  readonly ANVIL_ACCOUNT_PRIVATE_KEY: `0x${string}`
  readonly EFP_CONTRACT_ACCOUNT_METADATA: `0x${string}`
  readonly EFP_CONTRACT_LIST_METADATA: `0x${string}`
  readonly EFP_CONTRACT_LINT_MINTER: `0x${string}`
  readonly EFP_CONTRACT_LIST_REGISTRY: `0x${string}`
  readonly EFP_CONTRACT_LIST_RECORDS: `0x${string}`
  readonly QUIKNODE_ID: string
  readonly QUIKNODE_PREFIX: string
  readonly SNITCH_ID: string
  readonly START_BLOCK: string
  readonly BATCH_SIZE: number
}

declare module 'bun' {
  interface Env extends EnvironmentVariables {}
}

declare namespace NodeJs {
  interface ProcessEnv extends EnvironmentVariables {}
}
