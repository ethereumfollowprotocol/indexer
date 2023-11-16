import { raise } from '#/utilities'
import type { Config } from 'drizzle-kit'

const connectionString =
  process.env.DATABASE_URL_POOLED ?? raise('DATABASE_URL_POOLED is not defined')

export default {
  driver: 'pg',
  strict: true,
  verbose: true,
  out: './drizzle',
  breakpoints: true,
  dbCredentials: { connectionString },
  introspect: { casing: 'preserve' }
} satisfies Config
