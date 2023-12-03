import { logger } from '#/logger.ts'

export function raise(error: unknown): never {
  logger.fatal(error)
  throw typeof error === 'string' ? new Error(error) : error
}

/**
 * TODO:
 * not implemented
 */
export async function notifyError(error: unknown): Promise<void> {
  return logger.error(error)
}
