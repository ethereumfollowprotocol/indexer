import { type Row, database } from '#/database'
import { logger } from '#/logger'
import { colors } from '#/utilities/colors'
import type { Event } from '../event'

export class NewAccountMetadataValueHandler {
  async onNewAccountMetadataValue(event: Event): Promise<void> {
    const address: `0x${string}` = event.eventParameters.args['addr']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    // insert or update
    const row: Row<'account_metadata'> = {
      chain_id: event.chainId,
      contract_address: event.contractAddress.toLowerCase(),
      address: address.toLowerCase(),
      key: key,
      value: value
    }

    // check if value is already set for this chain_id/contract_address/address/key

    const query = database
      .selectFrom('account_metadata')
      .select('value')
      .where('chain_id', '=', event.chainId.toString())
      .where('contract_address', '=', event.contractAddress.toLowerCase())
      .where('address', '=', address.toLowerCase())
      .where('key', '=', key)
    // print
    const existing: { value: string } | undefined = await query.executeTakeFirst()
    if (existing === undefined) {
      // insert
      logger.log(
        `${
          colors.LIGHT_BLUE
        }(NewAccountMetadataValue) Insert account metadata chain_id=${event.chainId.toString()} contract_address=${event.contractAddress.toLowerCase()} address=${address.toLowerCase()} ${key}=${value} into \`account_metadata\` table${
          colors.ENDC
        }`
      )
      await database.insertInto('account_metadata').values([row]).executeTakeFirst()
    } else if (existing.value !== value) {
      // update
      logger.log(
        `${
          colors.LIGHT_MAGENTA
        }(NewAccountMetadataValue) Updating account metadata ${address.toLowerCase()} chain_id=${event.chainId.toString()} ${key}=${value} in \`account_metadata\` table${
          colors.ENDC
        }`
      )
      await database
        .updateTable('account_metadata')
        .set({ value: value })
        .where('chain_id', '=', event.chainId.toString())
        .where('contract_address', '=', event.contractAddress.toLowerCase())
        .where('address', '=', address.toLowerCase())
        .where('key', '=', key)
        .executeTakeFirst()
    } else {
      logger.log(
        `${
          colors.LIGHT_BLUE
        }(NewAccountMetadataValue) Account metadata ${address.toLowerCase()} chain_id=${event.chainId.toString()} ${key}=${value} already exists in \`account_metadata\` table${
          colors.ENDC
        }`
      )
    }
  }
}
