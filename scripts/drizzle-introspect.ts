#!/usr/bin/env bun

/**
 * Calls `drizzle-kit introspect:pg` to generate a schema file. Then, it fixes a bug in the generated file.
 * drizzle-kit has a bug where generated types in ./drizzle/schema.ts don't correctly wrap 2 things in sql``:
 * - `generate_ulid()`, and
 * - `(now() AT TIME ZONE 'utc'::text)`
 * This script fixes that.
 */
import bun from 'bun'
import path from 'node:path'

const introspectCommand = 'bun drizzle-kit introspect:pg --config=drizzle.config.ts'

const replace = [
  [/generate_ulid\(\)/g, 'sql`generate_ulid()`'],
  [/\(now\(\) AT TIME ZONE 'utc'::text\)/g, "sql`(now() AT TIME ZONE 'utc'::text)`"]
] satisfies Array<[RegExp, string]>

main().catch(error => {
  console.error(error)
  process.exit(1)
})

async function main() {
  const introspectProcess = bun.spawn({
    cmd: introspectCommand.split(' ')
  })
  const introspectResult = await new Response(introspectProcess.stdout).text()
  console.info(introspectResult)

  console.info('Fixing schema file...')
  const schemaFilePath = path.join(import.meta.dir, '../drizzle/schema.ts')
  const schemaFile = await bun
    .file(schemaFilePath, { type: 'application/text;charset=utf-8' })
    .text()

  const newSchemaFile = replace.reduce((previous, [search, replace]) => {
    return previous.replaceAll(search, replace)
  }, schemaFile)

  const writtenBytesSize = await bun.write(schemaFilePath, newSchemaFile, { mode: 0o644 })
  if (writtenBytesSize > 0 === false && newSchemaFile.length > 0) {
    throw new Error(`Failed to write to ${schemaFilePath}`)
  }
}
