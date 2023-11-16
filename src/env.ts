import { raise } from './utilities.ts'

export const env = Object.freeze({
  NODE_ENV: getEnvVariable('NODE_ENV'),
  ENABLE_DATABASE_LOGGING: getEnvVariable('ENABLE_DATABASE_LOGGING'),
  LLAMAFOLIO_ID: getEnvVariable('LLAMAFOLIO_ID'),
  ALCHEMY_ID: getEnvVariable('ALCHEMY_ID'),
  ANKR_ID: getEnvVariable('ANKR_ID'),
  INFURA_ID: getEnvVariable('INFURA_ID'),
  ALCHEMY_SEPOLIA_ID: getEnvVariable('ALCHEMY_SEPOLIA_ID'),
  ALCHEMY_OPTIMISM_ID: getEnvVariable('ALCHEMY_OPTIMISM_ID'),
  DATABASE_URL: getEnvVariable('DATABASE_URL'),
  DATABASE_URL_POOLED: getEnvVariable('DATABASE_URL_POOLED')
})

function getEnvVariable(name: keyof NodeJS.ProcessEnv) {
  return process.env[name] ?? raise(`environment variable ${name} not found`)
}
