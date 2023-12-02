import { indexerLogger } from '#/logger.ts'

export function raise(error: unknown): never {
  indexerLogger.fatal(error)
  throw typeof error === 'string' ? new Error(error) : error
}

/**
 * TODO:
 * not implemented
 */
export async function notifyError(error: unknown): Promise<void> {
  return indexerLogger.error(error)
}
