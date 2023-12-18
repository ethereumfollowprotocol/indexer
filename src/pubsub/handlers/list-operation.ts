import { database, type Row } from '#/database'
import { logger } from '#/logger'
import { decodeListOp, type ListOp } from '#/process/list-op'
import { decodeListRecord, type ListRecord } from '#/process/list-record'
import type { Event } from '../event'

export class ListOperationHandler {
  async onListOperation(event: Event): Promise<void> {
    const nonce: bigint = event.eventParameters.args['nonce']
    const op: `0x${string}` = event.eventParameters.args['op']
    const opBytes: Uint8Array = Buffer.from(op.slice(2), 'hex')
    const listOp: ListOp = decodeListOp(opBytes)

    const opDataView: DataView = new DataView(opBytes.buffer)
    // to get a number from a Uint8Array, we need to use the DataView class like so:
    const opVersion: number = opDataView.getUint8(0)
    const opCode: number = opDataView.getUint8(1)
    const opData: Uint8Array = opBytes.slice(2)
    const opDataHexstring: `0x${string}` = `0x${Buffer.from(opData).toString('hex')}`

    // log bright cyan so it stands out

    // insert
    const row: Row<'list_ops'> = {
      chain_id: event.chainId,
      contract_address: event.contractAddress.toLowerCase(),
      nonce: nonce,
      op: op,
      version: opVersion,
      code: opCode,
      data: opDataHexstring
    }
    logger.log(`\x1b[96m(ListOperation) Insert list op ${op} into \`list_ops\` table for nonce ${nonce}\x1b[0m`)
    await database.insertInto('list_ops').values([row]).executeTakeFirst()

    await this.processListOp(event.chainId, event.contractAddress.toLowerCase() as `0x${string}`, nonce, listOp)
  }

  async processListOp(chainId: bigint, contractAddress: `0x${string}`, nonce: bigint, listOp: ListOp): Promise<void> {
    if (listOp.version !== 1) {
      throw new Error(`Unsupported list op version ${listOp.version}`)
    }

    if (listOp.opcode === 1) {
      // ADD LIST RECORD

      // insert
      const listRecordHexstring: `0x${string}` = `0x${Buffer.from(listOp.data).toString('hex')}`
      const listRecord: ListRecord = decodeListRecord(listOp.data)
      const listRecordDataHexstring: `0x${string}` = `0x${Buffer.from(listRecord.data).toString('hex')}`

      const row: Row<'list_records'> = {
        chain_id: chainId,
        contract_address: contractAddress.toLowerCase(),
        nonce: nonce,
        record: listRecordHexstring,
        version: listRecord.version,
        type: listRecord.recordType,
        data: listRecordDataHexstring
      }
      // green log
      logger.log(`\x1b[92m(ListOperation) Add list record ${listRecordHexstring} to list nonce ${nonce} in db\x1b[0m`)
      await database.insertInto('list_records').values([row]).executeTakeFirst()
    } else if (listOp.opcode === 2) {
      // REMOVE LIST RECORD

      const listRecordHexstring: `0x${string}` = `0x${Buffer.from(listOp.data).toString('hex')}`
      logger.log(
        `\x1b[91m(ListOperation) Delete list record ${listRecordHexstring} from list nonce ${nonce} in db\x1b[0m`
      )
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
      logger.log(`\x1b[92m(ListOperation) Add tag "${tag}" to list record ${listRecord} in db\x1b[0m`)
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

      logger.log(`\x1b[91m(ListOperation) Delete tag "${tag}" from list record ${listRecord} in db\x1b[0m`)
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
