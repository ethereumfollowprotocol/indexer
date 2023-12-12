import { database } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class ListStorageLocationChangeHandler {
  async onListStorageLocationChange(event: Event): Promise<void> {
    const tokenId: bigint = event.eventParameters.args['tokenId']
    const listStorageLocation: `0x${string}` = event.eventParameters.args['listStorageLocation']
    const listStorageLocationBytes: Uint8Array = Buffer.from(listStorageLocation.slice(2), 'hex')

    // UPDATE list_nfts
    // SET list_storage_location = $1,
    //     list_storage_location_chain_id = $2,
    //     list_storage_location_contract_address = $3,
    //     list_storage_location_nonce = $4
    // WHERE chain_id = $2
    //       AND contract_address = $3
    //       AND token_id = $4
    let query = database.updateTable('list_nfts').set({ list_storage_location: listStorageLocation })
    if (listStorageLocationBytes.length === 1 + 1 + 32 + 20 + 32) {
      // [0] version byte should be 0x01
      // [1] list storage location type byte should be 0x01
      if (listStorageLocationBytes[0] === 0x01 && listStorageLocationBytes[1] === 0x01) {
        // [2-33] chain id
        const chainIdBytes: Uint8Array = listStorageLocationBytes.slice(2, 2 + 32)
        const chainId: bigint = chainIdBytes.reduce((acc, cur) => acc * 256n + BigInt(cur), 0n)
        // [34-53] contract address
        const contractAddressBytes: Uint8Array = listStorageLocationBytes.slice(2 + 32, 2 + 32 + 20)
        const contractAddress: `0x${string}` = `0x${Buffer.from(contractAddressBytes).toString('hex')}`
        // [54-85] nonce
        const nonceBytes: Uint8Array = listStorageLocationBytes.slice(2 + 32 + 20, 2 + 32 + 20 + 32)
        const nonce: bigint = nonceBytes.reduce((acc, cur) => acc * 256n + BigInt(cur), 0n)
        query = query.set({
          list_storage_location_chain_id: chainId,
          list_storage_location_contract_address: contractAddress,
          list_storage_location_nonce: nonce
        })
      }
    } else {
      // log error in red
      logger.log(
        `\x1b[91m(ListStorageLocationChange) List storage location ${listStorageLocation} is ${
          listStorageLocationBytes.length
        } bytes instead of ${1 + 1 + 32 + 20 + 32} bytes\x1b[0m`
      )
    }
    await query
      .where('chain_id', '=', event.chainId.toString())
      .where('contract_address', '=', event.contractAddress)
      .where('token_id', '=', tokenId.toString())
      .executeTakeFirst()
  }
}
