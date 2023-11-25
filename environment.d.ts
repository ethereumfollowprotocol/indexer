interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly LLAMAFOLIO_ID: string
  readonly MAINNET_ALCHEMY_ID: string
  readonly OPTIMISM_ALCHAMY_ID: string
  readonly SEPOLIA_ALCHEMY_ID: string
  readonly INFURA_ID: string
  readonly ANKR_ID: string
  readonly DATABASE_URL: string
  readonly DATABASE_URL_POOLED: string
  readonly ENABLE_DATABASE_LOGGING: string

  readonly ANVIL_ACCOUNT_PRIVATE_KEY: string
}

declare namespace NodeJS {
  interface ProcessEnv extends EnvironmentVariables {}
}
