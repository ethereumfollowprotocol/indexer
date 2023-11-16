import { createConsola } from 'consola'

export const indexerLogger = createConsola({
  defaults: { tag: '@efp/indexer' },
  formatOptions: {
    date: true,
    colors: true
  }
})
