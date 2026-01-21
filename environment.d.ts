interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly CHAIN_ID: '1' | '10' | '8453'
  readonly DATABASE_URL: string
  readonly EFP_CONTRACT_ACCOUNT_METADATA: `0x${string}`
  readonly EFP_CONTRACT_LIST_REGISTRY: `0x${string}`
  readonly EFP_CONTRACT_LIST_RECORDS: `0x${string}`
  readonly EFP_CONTRACT_LIST_RECORDS_V2: `0x${string}`
  readonly HEARTBEAT_URL: string
  readonly START_BLOCK: string
  readonly BATCH_SIZE: number
  readonly RECOVER_HISTORY: string
  readonly PRIMARY_RPC_BASE: string
  readonly SECONDARY_RPC_BASE: string
  readonly PRIMARY_RPC_OP: string
  readonly SECONDARY_RPC_OP: string
  readonly PRIMARY_RPC_ETH: string
  readonly SECONDARY_RPC_ETH: string
  readonly RECORDS_ONLY: string
}

declare module 'bun' {
  interface Env extends EnvironmentVariables {}
}

declare namespace NodeJs {
  interface ProcessEnv extends EnvironmentVariables {}
}
