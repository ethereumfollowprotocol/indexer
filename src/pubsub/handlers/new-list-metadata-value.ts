import { database, type Row } from '#/database'
import { logger } from '#/logger'
import type { Event } from '../event'

export class NewListMetadataValueHandler {
  // CREATE TABLE public.list_metadata (
  //     chain_id bigint NOT NULL,
  //     contract_address character varying(42) NOT NULL,
  //     nonce bigint NOT NULL,
  //     key character varying(255) NOT NULL,
  //     value character varying(255) NOT NULL
  // );
  async onNewListMetadataValue(event: Event): Promise<void> {
    if (event.contractName !== 'EFPListRecords' || event.eventParameters.eventName !== 'ValueSet') {
      return
    }

    const token_id: bigint = event.eventParameters.args['tokenId']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    // insert or update
    const row: Row<'list_metadata'> = {
      chain_id: event.chainId,
      contract_address: event.contractAddress,
      token_id: token_id,
      key: key,
      value: value
    }
    logger.log(
      `\x1b[33m(NewListMetadataValue) EFP List #${token_id} insert ${key}=${value} into \`list_metadata\` table\x1b[0m`
    )
    await database.insertInto('list_metadata').values([row]).executeTakeFirst()
  }
}
