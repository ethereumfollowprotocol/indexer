import { getAddress, type Hex } from 'viem'
import { raise } from './utilities'

export const env = Object.freeze({
  NODE_ENV: getEnvVariable('NODE_ENV'),
  ENABLE_DATABASE_LOGGING: getEnvVariable('ENABLE_DATABASE_LOGGING'),
  LLAMAFOLIO_ID: getEnvVariable('LLAMAFOLIO_ID'),
  MAINNET_ALCHEMY_ID: getEnvVariable('MAINNET_ALCHEMY_ID'),
  ANKR_ID: getEnvVariable('ANKR_ID'),
  INFURA_ID: getEnvVariable('INFURA_ID'),
  SEPOLIA_ALCHEMY_ID: getEnvVariable('SEPOLIA_ALCHEMY_ID'),
  OPTIMISM_ALCHEMY_ID: getEnvVariable('OPTIMISM_ALCHEMY_ID'),
  ETHEREUM_LOCAL_NODE_URL: getEnvVariable('ETHEREUM_LOCAL_NODE_URL'),
  DATABASE_URL: getEnvVariable('DATABASE_URL'),
  DATABASE_URL_POOLED: getEnvVariable('DATABASE_URL_POOLED'),
  ANVIL_ACCOUNT_PRIVATE_KEY: getEnvVariable('ANVIL_ACCOUNT_PRIVATE_KEY') as Hex,
  CHAIN_ID: getEnvVariable('CHAIN_ID') as EnvironmentVariables['CHAIN_ID'],
  EFP_CONTRACTS: {
    ACCOUNT_METADATA: getAddress(getEnvVariable('EFP_CONTRACT_ACCOUNT_METADATA')),
    LIST_METADATA: getAddress(getEnvVariable('EFP_CONTRACT_LIST_METADATA')),
    LIST_MINTER: getAddress(getEnvVariable('EFP_CONTRACT_LINT_MINTER')),
    LIST_REGISTRY: getAddress(getEnvVariable('EFP_CONTRACT_LIST_REGISTRY')),
    LIST_RECORDS: getAddress(getEnvVariable('EFP_CONTRACT_LIST_RECORDS'))
  }
})

function getEnvVariable(name: keyof EnvironmentVariables) {
  return process.env[name] ?? raise(`environment variable ${name} not found`)
}
