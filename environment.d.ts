interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly LLAMAFOLIO_ID: string
  readonly ALCHEMY_ID: string
  readonly ALCHEMY_SEPOLIA_ID: string
  readonly ALCHEMY_OPTIMISM_ID: string
  readonly INFURA_ID: string
  readonly ANKR_ID: string
  readonly DATABASE_URL: string
  readonly DATABASE_URL_POOLED: string
  readonly ENABLE_DATABASE_LOGGING: string
}

declare namespace NodeJS {
  interface ProcessEnv extends EnvironmentVariables {}
}
