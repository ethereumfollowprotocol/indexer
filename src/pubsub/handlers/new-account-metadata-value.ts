import { database, type Row } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class NewAccountMetadataValueHandler {
  async onNewAccountMetadataValue(event: Event): Promise<void> {
    if (event.contractName !== 'EFPAccountMetadata' || event.eventParameters.eventName !== 'ValueSet') {
      return
    }

    const address: `0x${string}` = event.eventParameters.args['addr']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    // insert or update
    const row: Row<'account_metadata'> = {
      chain_id: event.chainId,
      contract_address: event.contractAddress,
      address: address,
      key: key,
      value: value
    }
    logger.log(`(NewAccountMetadataValue) Account ${address} insert ${key}=${value} into \`account_metadata\` table`)

    // check if value is already set for this chain_id/contract_address/address/key
    const existing = await database
      .selectFrom('account_metadata')
      .where('chain_id', '=', event.chainId.toString())
      .where('contract_address', '=', event.contractAddress)
      .where('address', '=', address)
      .where('key', '=', key)
      .executeTakeFirst()
    if (existing) {
      // update
      logger.log(
        `\x1b[95m(NewAccountMetadataValue) Updating account metadata ${address} ${key}=${value} in \`account_metadata\` table\x1b[0m`
      )
      await database
        .updateTable('account_metadata')
        .set({ value: value })
        .where('chain_id', '=', event.chainId.toString())
        .where('contract_address', '=', event.contractAddress)
        .where('address', '=', address)
        .where('key', '=', key)
        .executeTakeFirst()
    } else {
      // insert
      logger.log(
        `\x1b[94m(NewAccountMetadataValue) Insert account metadata ${address} ${key}=${value} into \`account_metadata\` table\x1b[0m`
      )
      await database.insertInto('account_metadata').values([row]).executeTakeFirst()
    }
  }
}
