/**
 * Utility types that are not domain specific and used in multiple places
 */

export type NonNullable<T> = T extends null | undefined ? never : T

// @link https://x.com/mattpocockuk/status/1622730173446557697?s=20
export type Pretty<T> = {
  [K in keyof T]: T[K]
} & {}

export type Flatten<T> = T extends any[] ? T[number] : T

export type ExtractTypeFromUnion<T, Excluded> = T extends (infer U & Excluded) | undefined ? U : never
