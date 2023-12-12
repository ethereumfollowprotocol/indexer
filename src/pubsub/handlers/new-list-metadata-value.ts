import { database, type Row } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class NewListMetadataValueHandler {
  async onNewListMetadataValue(event: Event): Promise<void> {
    const nonce: bigint = event.eventParameters.args['nonce']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    // insert or update
    const row: Row<'list_metadata'> = {
      chain_id: event.chainId,
      contract_address: event.contractAddress,
      nonce,
      key,
      value
    }
    logger.log(
      `\x1b[33m(NewListMetadataValue) EFP List w/ nonce: ${nonce} insert ${key}=${value} into \`list_metadata\` table\x1b[0m`
    )
    await database.insertInto('list_metadata').values([row]).executeTakeFirst()
  }
}
