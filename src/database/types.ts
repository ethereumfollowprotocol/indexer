import type { Database } from '#/types/generated/database.ts'

export type DB = {
  [TableName in keyof Tables]: {
    [ColumnName in
      keyof Tables[TableName]['Insert']]-?: undefined extends Tables[TableName]['Insert'][ColumnName]
      ? NoUndefined<Tables[TableName]['Insert'][ColumnName]>
      : Tables[TableName]['Insert'][ColumnName]
  }
}

type Tables = Database['public']['Tables']

type NoUndefined<T> = T extends undefined ? never : T

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]
