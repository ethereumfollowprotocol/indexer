import { indexerLogger } from '#/logger.ts'

export function raise(error: unknown): never {
  indexerLogger.fatal(error)
  throw typeof error === 'string' ? new Error(error) : error
}
