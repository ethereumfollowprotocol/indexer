interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly LLAMAFOLIO_ID: string
  readonly MAINNET_ALCHEMY_ID: string
  readonly OPTIMISM_ALCHEMY_ID: string
  readonly SEPOLIA_ALCHEMY_ID: string
  readonly INFURA_ID: string
  readonly ANKR_ID: string
  readonly ETHEREUM_LOCAL_NODE_URL: string
  readonly DATABASE_URL: string
  readonly DATABASE_URL_POOLED: string
  readonly ENABLE_DATABASE_LOGGING: string
  readonly ANVIL_ACCOUNT_PRIVATE_KEY: string

  readonly EFP_CONTRACT_ACCOUNT_METADATA: string
  readonly EFP_CONTRACT_LIST_METADATA: string
  readonly EFP_CONTRACT_LINT_MINTER: string
  readonly EFP_CONTRACT_LIST_REGISTRY: string
  readonly EFP_CONTRACT_LIST_RECORDS: string

  readonly CHAIN_ID: '1' | '10' | '31337' | '11155111' | '11155420'
}

declare namespace NodeJS {
  interface ProcessEnv extends EnvironmentVariables {}
}
