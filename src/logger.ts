import { createConsola } from 'consola'

export const logger = createConsola({
  defaults: { tag: 'efp-indexer' },
  formatOptions: {
    date: true,
    colors: true
  }
})
