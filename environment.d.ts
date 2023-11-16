interface EnvironmentVariables {
  readonly NODE_ENV: 'development' | 'production' | 'test'
  readonly LLAMAFOLIO_ID: string
  readonly ALCHEMY_ID: string
  readonly ALCHEMY_SEPOLIA_ID: string
  readonly ALCHEMY_OPTIMISM_ID: string
  readonly INFURA_ID: string
  readonly ANKR_ID: string
  readonly SUPABASE_URL: string
  readonly SUPABASE_KEY: string
  readonly DATABASE_HOST: string
  readonly DATABASE_PORT: string
  readonly DATABASE_USER: string
  readonly DATABASE_NAME: string
  readonly DATABASE_PASSWORD: string
  readonly ENABLE_DATABASE_LOGGING: string

  readonly DATABASE_URL: string
  readonly DATABASE_URL_POOLED: string
}

declare namespace NodeJS {
  interface ProcessEnv extends EnvironmentVariables {}
}
