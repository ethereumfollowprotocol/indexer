import { raise } from '#/utilities'
import type { Config } from 'drizzle-kit'

const connectionString =
  process.env.DATABASE_URL_POOLED ?? raise('DATABASE_URL_POOLED is not defined')

export default ({
  driver: 'pg',
  strict: true,
  verbose: true,
  out: './drizzle',
  schema: './src/database/schema/*.ts',
  breakpoints: true,
  dbCredentials: { connectionString },
  introspect: { casing: 'camel' }
} satisfies Config)
