import { type Row, database } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class OwnershipTransferredHandler {
  async onOwnershipTransferred(event: Event): Promise<void> {
    // this was a new contract that got deployed and transferred
    // ownership to the owner
    const previousOwner = event.eventParameters.args['previousOwner']
    const newOwner = event.eventParameters.args['newOwner']
    if (previousOwner === '0x0000000000000000000000000000000000000000') {
      const contractsRow: Row<'contracts'> = {
        chain_id: event.chainId,
        address: event.contractAddress.toLowerCase(),
        name: event.contractName,
        owner: newOwner.toLowerCase()
      }
      logger.log(`\x1b[96m(OwnershipTransferred) Insert ${event.contractName} contract into \`contracts\` table\x1b[0m`)
      await database.insertInto('contracts').values([contractsRow]).executeTakeFirst()
    } else {
      // contract ownership was transferred but the contract should already
      // be in the database

      // we will update the owner in the database
      logger.log(
        `\x1b[95m(OwnershipTransferred) Updating ${event.contractName} contract owner from ${previousOwner} to ${newOwner} in \`contracts\` table\x1b[0m`
      )
      await database
        .updateTable('contracts')
        .set({ owner: newOwner })
        .where('chain_id', '=', event.chainId.toString())
        .where('address', '=', event.contractAddress.toLowerCase())
        .executeTakeFirst()
    }
  }
}
