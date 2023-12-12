import { database, type Row } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class TransferHandler {
  async onTransfer(event: Event): Promise<void> {
    const from: string = event.eventParameters.args['from']
    const to: string = event.eventParameters.args['to']
    if (from === '0x0000000000000000000000000000000000000000') {
      // insert as new row
      const row: Row<'list_nfts'> = {
        chain_id: event.chainId,
        contract_address: event.contractAddress,
        token_id: event.eventParameters.args['tokenId'],
        owner: to,
        // list_manager: '',
        list_user: to
        // list_storage_location: '',
        // list_storage_location_chain_id: 0n,
        // list_storage_location_contract_address: ''
        // list_storage_location_nonce: 0n,
      }

      logger.log(`\x1b[94m(Transfer) Insert ${event.eventParameters.eventName} event \`list_nfts\` table\x1b[0m`)
      await database.insertInto('list_nfts').values([row]).executeTakeFirst()
    } else {
      // update existing row
      logger.log(`\x1b[93m(Transfer) Update ${event.eventParameters.eventName} event in db\x1b[0m`)
      await database
        .updateTable('list_nfts')
        .set({ owner: to })
        .where('chain_id', '=', event.chainId.toString())
        .where('contract_address', '=', event.contractAddress)
        .where('token_id', '=', event.eventParameters.args['tokenId'])
        .executeTakeFirst()
    }
  }
}
