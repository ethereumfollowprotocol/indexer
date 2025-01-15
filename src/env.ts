import { raise } from './utilities'

export const env = Object.freeze({
  NODE_ENV: getEnvVariable('NODE_ENV'),
  DATABASE_URL: getEnvVariable('DATABASE_URL'),
  CHAIN_ID: getEnvVariable('CHAIN_ID'),
  SNITCH_ID: getEnvVariable('SNITCH_ID') ?? undefined,
  START_BLOCK: getEnvVariable('START_BLOCK'),
  BATCH_SIZE: getEnvVariable('BATCH_SIZE'),
  RECOVER_HISTORY: getEnvVariable('RECOVER_HISTORY'),
  EFP_CONTRACTS: {
    ACCOUNT_METADATA: getEnvVariable('EFP_CONTRACT_ACCOUNT_METADATA'),
    LIST_MINTER: getEnvVariable('EFP_CONTRACT_LINT_MINTER'),
    LIST_REGISTRY: getEnvVariable('EFP_CONTRACT_LIST_REGISTRY'),
    LIST_RECORDS: getEnvVariable('EFP_CONTRACT_LIST_RECORDS')
  },
  PRIMARY_RPC_BASE: getEnvVariable('PRIMARY_RPC_BASE'),
  SECONDARY_RPC_BASE: getEnvVariable('SECONDARY_RPC_BASE'),
  PRIMARY_RPC_OP: getEnvVariable('PRIMARY_RPC_OP'),
  SECONDARY_RPC_OP: getEnvVariable('SECONDARY_RPC_OP'),
  PRIMARY_RPC_ETH: getEnvVariable('PRIMARY_RPC_ETH'),
  SECONDARY_RPC_ETH: getEnvVariable('SECONDARY_RPC_ETH'),
  RECORDS_ONLY: getEnvVariable('RECORDS_ONLY'),
})

function getEnvVariable<T extends keyof EnvironmentVariables>(name: T) {
  return process.env[name] ?? raise(`environment variable ${name} not found`)
}
