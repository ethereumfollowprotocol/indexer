import { database, type Row } from '#/database'
import { logger } from '#/logger'
import { decodeListOp, type ListOp } from '#/process/list-op'
import { sql, type QueryResult, type RawBuilder } from 'kysely'
import type { Event } from '../event'

export class ListOpHandler {
  async onListOp(event: Event): Promise<void> {
    const nonce: bigint = event.eventParameters.args['nonce']
    const op: `0x${string}` = event.eventParameters.args['op']

    const query: RawBuilder<unknown> = sql`SELECT public.handle_contract_event__ListOp(
      ${event.chainId},
      ${event.contractAddress},
      ${nonce},
      ${op}
    )`
    const eventSignature: string = `${event.eventParameters.eventName}(${nonce}, ${op})`
    logger.info(eventSignature)

    try {
      const result: QueryResult<unknown> = await query.execute(database)
      // sleep for 1 sec
      await new Promise(resolve => setTimeout(resolve, 1000))

      if (!result || result.rows.length === 0) {
        logger.warn(`${eventSignature} query returned no rows`)
        return
      }
    } catch (error: any) {
      logger.error(`${eventSignature} Error processing event: ${error.message}`)
      process.exit(1)
    }

    // STEP 2: we will do this later
    const listOp: ListOp = decodeListOp(op)
    await this.processListOp(event.chainId, event.contractAddress.toLowerCase() as `0x${string}`, nonce, listOp)
  }

  async processListOp(chainId: bigint, contractAddress: `0x${string}`, nonce: bigint, listOp: ListOp): Promise<void> {
    if (listOp.version !== 1) {
      throw new Error(`Unsupported list op version ${listOp.version}`)
    }

    if (listOp.opcode === 1) {
      // do nothing
    } else if (listOp.opcode === 2) {
      // REMOVE LIST RECORD

      const listRecordHexstring: `0x${string}` = `0x${Buffer.from(listOp.data).toString('hex')}`
      logger.log(`\x1b[91m(ListOp) Delete list record ${listRecordHexstring} from list nonce ${nonce} in db\x1b[0m`)
      const result = await database
        .deleteFrom('list_records')
        .where('chain_id', '=', chainId.toString())
        .where('contract_address', '=', contractAddress.toLowerCase())
        .where('nonce', '=', nonce.toString())
        .where('record', '=', listRecordHexstring)
        .executeTakeFirst()
      logger.log(result)
    } else if (listOp.opcode === 3) {
      // ADD LIST RECORD TAG

      if (listOp.version !== 1) {
        throw new Error(`Unsupported list op version ${listOp.version}`)
      }
      const listRecordBytes: Uint8Array = listOp.data.slice(0, 1 + 1 + 20) // version, code, list record
      const listRecord: string = `0x${Buffer.from(listRecordBytes).toString('hex')}`
      const tagBytes: Uint8Array = listOp.data.slice(1 + 1 + 20) // tag
      const tag: string = Buffer.from(tagBytes).toString('utf-8')

      const row: Row<'list_record_tags'> = {
        chain_id: chainId,
        contract_address: contractAddress.toLowerCase(),
        nonce: nonce,
        record: listRecord,
        tag: tag
      }
      // green log
      logger.log(`\x1b[92m(ListOp) Add tag "${tag}" to list record ${listRecord} in db\x1b[0m`)
      // TODO: ensure not duplicate tag
      await database.insertInto('list_record_tags').values([row]).executeTakeFirst()
    } else if (listOp.opcode === 4) {
      // REMOVE LIST RECORD TAG

      if (listOp.version !== 1) {
        throw new Error(`Unsupported list op version ${listOp.version}`)
      }
      const listRecordBytes: Uint8Array = listOp.data.slice(0, 1 + 1 + 20) // version, code, list record
      const listRecord: string = `0x${Buffer.from(listRecordBytes).toString('hex')}`
      const tagBytes: Uint8Array = listOp.data.slice(1 + 1 + 20) // tag
      const tag: string = Buffer.from(tagBytes).toString('utf-8')

      logger.log(`\x1b[91m(ListOp) Delete tag "${tag}" from list record ${listRecord} in db\x1b[0m`)
      const result = await database
        .deleteFrom('list_record_tags')
        .where('chain_id', '=', chainId.toString())
        .where('contract_address', '=', contractAddress.toLowerCase())
        .where('nonce', '=', nonce.toString())
        .where('record', '=', listRecord)
        .where('tag', '=', tag)
        .executeTakeFirst()
      logger.log(result)
    } else {
      // unknown list op code
      throw new Error(`Unsupported list op code ${listOp.opcode}`)
    }
  }
}
