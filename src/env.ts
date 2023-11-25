import { raise } from './utilities.ts'

export const env = Object.freeze({
  NODE_ENV: getEnvVariable('NODE_ENV'),
  ENABLE_DATABASE_LOGGING: getEnvVariable('ENABLE_DATABASE_LOGGING'),
  LLAMAFOLIO_ID: getEnvVariable('LLAMAFOLIO_ID'),
  MAINNET_ALCHEMY_ID: getEnvVariable('MAINNET_ALCHEMY_ID'),
  ANKR_ID: getEnvVariable('ANKR_ID'),
  INFURA_ID: getEnvVariable('INFURA_ID'),
  SEPOLIA_ALCHEMY_ID: getEnvVariable('SEPOLIA_ALCHEMY_ID'),
  OPTIMISM_ALCHEMY_ID: getEnvVariable('OPTIMISM_ALCHAMY_ID'),
  DATABASE_URL: getEnvVariable('DATABASE_URL'),
  DATABASE_URL_POOLED: getEnvVariable('DATABASE_URL_POOLED')
})

function getEnvVariable(name: keyof EnvironmentVariables) {
  return process.env[name] ?? raise(`environment variable ${name} not found`)
}
