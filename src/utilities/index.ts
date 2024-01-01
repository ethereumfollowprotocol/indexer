import { logger } from '#/logger.ts'

export function raise(error: unknown): never {
  throw typeof error === 'string' ? new Error(error) : error
}

export const timestamp = () => new Date().toISOString()

export function nonNullable<T>(value: T): value is NonNullable<T> {
  return value != null
}

export async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * TODO:
 * not implemented
 */
export async function notifyError(error: unknown): Promise<void> {
  return logger.error(error)
}
