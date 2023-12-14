import { database } from '#/database'
import { logger } from '#/logger'
import { colors } from '#/utilities/colors'
import type { Event } from '../event'

export class ListManagerChangeHandler {
  async onListManagerChange(event: Event): Promise<void> {
    const nonce: bigint = event.eventParameters.args['nonce'] as bigint
    const manager: `0x${string}` = event.eventParameters.args['manager'].toLowerCase() as `0x${string}`
    logger.log(`${colors.ORANGE}(ListManagerChange) nonce: ${nonce}, manager: ${manager}${colors.ENDC}`)

    // find the token id which matches this nonce
    const query = database
      .selectFrom('list_nfts')
      .select('token_id')
      .where('list_storage_location_chain_id', '=', event.chainId.toString())
      .where('list_storage_location_contract_address', '=', event.contractAddress.toLowerCase())
      .where('list_storage_location_nonce', '=', nonce.toString())
    let tokenIdResult: { token_id: string }[] = await query.execute()
    let tokenIds: string[] = tokenIdResult.map(({ token_id }) => token_id)

    if (tokenIds.length === 0) {
      // wait 3 seconds and try one more time
      await new Promise(resolve => setTimeout(resolve, 3000))
      tokenIdResult = await query.execute()
      tokenIds = tokenIdResult.map(({ token_id }) => token_id)
      if (tokenIds.length === 0) {
        // red
        logger.error(`\x1b[31m(ListManagerChange) No token ids found for nonce ${nonce}\x1b[0m`)
        return
      }
    }
    logger.log(
      `${colors.ORANGE}(ListManagerChange) nonce: ${nonce}, manager: ${manager} tokenIds: ${tokenIds}${colors.ENDC}`
    )

    // update list_nfts.list_manager WHERE list_nfts.token_id IN tokenIdResult.token_id
    const result = await database
      .updateTable('list_nfts')
      .set({ list_manager: manager })
      .where('token_id', 'in', tokenIds)
      .executeTakeFirst()
    logger.log(
      `${colors.ORANGE}(ListManagerChange) Updated ${result.numChangedRows} rows in \`list_nfts\` table with manager ${manager}${colors.ENDC}`
    )
  }
}
