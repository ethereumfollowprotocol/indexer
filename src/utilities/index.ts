import { logger } from '#/logger.ts'

export const timestamp = () => new Date().toISOString()

export function raise(error: unknown): never {
  throw typeof error === 'string' ? new Error(error) : error
}

/**
 * TODO:
 * not implemented
 */
export async function notifyError(error: unknown): Promise<void> {
  return logger.error(error)
}
