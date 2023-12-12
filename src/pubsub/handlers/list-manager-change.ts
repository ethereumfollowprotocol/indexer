import { database } from '#/database'
import type { Event } from '../event'

export class ListManagerChangeHandler {
  async onListManagerChange(event: Event): Promise<void> {
    if (event.contractName !== 'EFPListRecords' || event.eventParameters.eventName !== 'ListManagerChange') {
      return
    }

    // emit ListManagerChange(nonce, manager);

    const nonce: bigint = event.eventParameters.args['nonce']
    const manager: `0x${string}` = event.eventParameters.args['manager']
    console.log(`(ListManagerChange) nonce: ${nonce}, manager: ${manager}`)

    console.log(
      `SELECT token_id FROM list_nfts WHERE list_storage_location_chain_id = ${event.chainId.toString()} AND list_storage_location_contract_address = ${
        event.contractAddress
      } AND list_storage_location_nonce = ${nonce.toString()}`
    )

    // find the token id which matches this nonce
    const query = database
      .selectFrom('list_nfts')
      .select('token_id')
      .where('list_storage_location_chain_id', '=', event.chainId.toString())
      .where('list_storage_location_contract_address', '=', event.contractAddress)
      .where('list_storage_location_nonce', '=', nonce.toString())
    let tokenIdResult: { token_id: string }[] = await query.execute()
    let tokenIds: string[] = tokenIdResult.map(({ token_id }) => token_id)
    // console.log(`(ListManagerChange) tokenIdResult: ${JSON.stringify(tokenIdResult, undefined, 2)}`)

    if (tokenIds.length === 0) {
      // wait 3 seconds and try one more time
      await new Promise(resolve => setTimeout(resolve, 3000))
      tokenIdResult = await query.execute()
      tokenIds = tokenIdResult.map(({ token_id }) => token_id)
      // console.log(`(ListManagerChange) tokenIdResult: ${JSON.stringify(tokenIdResult, undefined, 2)}`)
      if (tokenIds.length === 0) {
        // red
        console.error(`\x1b[31m(ListManagerChange) No token ids found for nonce ${nonce}\x1b[0m`)
        return
      }
    }

    // update list_nfts.list_manager WHERE list_nfts.token_id IN tokenIdResult.token_id
    const result = await database
      .updateTable('list_nfts')
      .set({ list_manager: manager })
      .where('token_id', 'in', tokenIds)
      .executeTakeFirst()
    console.log(
      `(ListManagerChange) Updated ${result.numChangedRows} rows in \`list_nfts\` table with manager ${manager}`
    )
  }
}
