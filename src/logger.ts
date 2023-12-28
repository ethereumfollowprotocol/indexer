import { createConsola } from 'consola'
import { environmentInfo } from '#/utilities/detect-environment.ts'

export const logger = createConsola({
  // when running in docker, we don't want to end up with double tags: efp-indexer efp-indexer
  defaults: { tag: environmentInfo.isDocker ? '' : 'efp-indexer' },
  formatOptions: {
    date: true,
    colors: true
  }
})
