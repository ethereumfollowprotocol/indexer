import { EFPAccountMetadataABI, EFPListMinterABI, EFPListRecordsABI, EFPListRegistryABI } from '#/abi'
import { database, type Row } from '#/database'
import { logger } from '#/logger'
import { decodeListOp, type ListOp } from '#/process/list-op'
import { decodeListRecord, type ListRecord } from '#/process/list-record'
import { timestamp } from '#/utilities'
import type { Abi } from 'viem'
import type { Event } from '../event'
import { TransferHandler } from './transfer'

/**
 * Interface defining the structure and methods for an EventSubscriber.
 */
export interface EventSubscriber {
  onEvent(event: Event): Promise<void>
}

/**
 * Abstract base class representing a generic event subscriber for Ethereum
 * smart contracts. This class provides a common structure and functionalities
 * for event subscribers, which can be specialized for different Ethereum smart
 * contracts.
 */
export abstract class ContractEventSubscriber implements EventSubscriber {
  /**
   * Constructs an EventSubscriber.
   * @param contractName - The name of the contract, used for easier identification and logging.
   * @param abi - The ABI of the contract, used for decoding event logs.
   * @param address - The Ethereum address of the contract.
   */
  constructor(
    /** Contract name for easier identification. */
    public readonly contractName: string,

    /** ABI of the contract for decoding event logs. */
    public readonly abi: Abi,

    /** Ethereum address of the contract. */
    public readonly address: `0x${string}`
  ) {}

  /**
   * Generic handler for log events. This function should be overridden by subclasses to process each log.
   * @param log - The log to process.
   */
  async onEvent(event: Event): Promise<void> {
    // this.log(event)
  }

  /**
   * Default log processing implementation. Decodes the log and logs the output.
   * @param log - The log to process.
   */
  protected log(event: Event): void {
    function customSerializer(_: string, value: any): any {
      return typeof value === 'bigint' ? value.toString() : value
    }

    logger.log(`[${this.contractName}]`, JSON.parse(JSON.stringify(event, customSerializer, 2)))
  }
}

export class EFPAccountMetadataSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPAccountMetadata', EFPAccountMetadataABI, address)
  }
}

export class EFPListRegistrySubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRegistry', EFPListRegistryABI, address)
  }
}

export class EFPListRecordsSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListRecords', EFPListRecordsABI, address)
  }
}

export class EFPListMinterSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListMinter', EFPListMinterABI, address)
  }
}

export class DatabaseUploader implements EventSubscriber {
  /**
   * Generic handler for log events. This function should be overridden by subclasses to process each log.
   * @param log - The log to process.
   */
  async onEvent(event: Event): Promise<void> {
    // eventParameters will have an args field
    const serializableEventParameters: { eventName: string; args: Record<string, any> } = {
      eventName: event.eventParameters.eventName,
      args: {}
    }
    for (const key in event.eventParameters.args) {
      // convert bigints to strings
      const value = event.eventParameters.args[key]
      serializableEventParameters.args[key] = typeof value === 'bigint' ? value.toString() : value
    }

    const eventName: string = event.eventParameters.eventName
    const row: Row<'events'> = {
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      contract_address: event.contractAddress,
      // problem: we don't have event name here
      event_name: event.eventParameters.eventName,
      event_parameters: JSON.stringify(serializableEventParameters),
      timestamp: timestamp()
    }

    logger.log(`Insert ${event.eventParameters.eventName} event into \`events\` table`)
    await database.insertInto('events').values([row]).executeTakeFirst()

    if (eventName === 'ListOperation') {
      await this.onListOperation(event)
    } else if (eventName === 'OwnershipTransferred') {
      await this.onOwnershipTransferred(event)
    } else if (eventName === 'Transfer') {
      await new TransferHandler().onTransfer(event)
    } else if (eventName === 'ListStorageLocationChange') {
      await this.onListStorageLocationChange(event)
    } else if (event.contractName === 'EFPAccountMetadata' && eventName === 'ValueSet') {
      await this.onAccountMetadataValueSet(event)
    } else if (event.contractName === 'EFPListRecords' && eventName === 'ValueSet') {
      await this.onListMetadataValueSet(event)
    }
  }

  async onListStorageLocationChange(event: Event): Promise<void> {
    if (event.eventParameters.eventName !== 'ListStorageLocationChange') {
      return
    }

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
        `\x1b[91mList storage location ${listStorageLocation} is ${listStorageLocationBytes.length} bytes instead of ${
          1 + 1 + 32 + 20 + 32
        } bytes\x1b[0m`
      )
    }
    await query
      .where('chain_id', '=', event.chainId.toString())
      .where('contract_address', '=', event.contractAddress)
      .where('token_id', '=', tokenId.toString())
      .executeTakeFirst()
  }

  //   CREATE TABLE public.account_metadata (
  //     chain_id bigint NOT NULL,
  //     contract_address character varying(42) NOT NULL,
  //     address character varying(42) NOT NULL,
  //     key character varying(255) NOT NULL,
  //     value character varying(255) NOT NULL
  // );
  async onAccountMetadataValueSet(event: Event): Promise<void> {
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
    logger.log(`Account ${address} insert ${key}=${value} into \`account_metadata\` table`)

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
      logger.log(`\x1b[95mUpdating account metadata ${address} ${key}=${value} in \`account_metadata\` table\x1b[0m`)
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
      logger.log(`\x1b[94mInsert account metadata ${address} ${key}=${value} into \`account_metadata\` table\x1b[0m`)
      await database.insertInto('account_metadata').values([row]).executeTakeFirst()
    }
  }

  // CREATE TABLE public.list_metadata (
  //     chain_id bigint NOT NULL,
  //     contract_address character varying(42) NOT NULL,
  //     nonce bigint NOT NULL,
  //     key character varying(255) NOT NULL,
  //     value character varying(255) NOT NULL
  // );
  async onListMetadataValueSet(event: Event): Promise<void> {
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
    logger.log(`\x1b[33mEFP List #${token_id} insert ${key}=${value} into \`list_metadata\` table\x1b[0m`)
    await database.insertInto('list_metadata').values([row]).executeTakeFirst()
  }

  async onListOperation(event: Event): Promise<void> {
    if (event.eventParameters.eventName !== 'ListOperation') {
      return
    }

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
      contract_address: event.contractAddress,
      nonce: nonce,
      op: op,
      version: opVersion,
      code: opCode,
      data: opDataHexstring
    }
    logger.log(`\x1b[96mInsert list op ${op} into \`list_ops\` table for nonce ${nonce}\x1b[0m`)
    await database.insertInto('list_ops').values([row]).executeTakeFirst()

    await this.processListOp(event.chainId, event.contractAddress, nonce, listOp)
  }

  async processListOp(chainId: bigint, contractAddress: `0x${string}`, nonce: bigint, listOp: ListOp): Promise<void> {
    if (listOp.version !== 1) {
      throw new Error(`Unsupported list op version ${listOp.version}`)
    }

    if (listOp.code === 1) {
      // ADD LIST RECORD

      // insert
      const listRecordHexstring: `0x${string}` = `0x${Buffer.from(listOp.data).toString('hex')}`
      const listRecord: ListRecord = decodeListRecord(listOp.data)
      const listRecordDataHexstring: `0x${string}` = `0x${Buffer.from(listRecord.data).toString('hex')}`

      const row: Row<'list_records'> = {
        chain_id: chainId,
        contract_address: contractAddress,
        nonce: nonce,
        record: listRecordHexstring,
        version: listRecord.version,
        type: listRecord.recordType,
        data: listRecordDataHexstring
      }
      // green log
      logger.log(`\x1b[92mAdd list record ${listRecordHexstring} to list nonce ${nonce} in db\x1b[0m`)
      await database.insertInto('list_records').values([row]).executeTakeFirst()
    } else if (listOp.code === 2) {
      // REMOVE LIST RECORD

      const listRecordHexstring: `0x${string}` = `0x${Buffer.from(listOp.data).toString('hex')}`
      logger.log(`\x1b[91mDelete list record ${listRecordHexstring} from list nonce ${nonce} in db\x1b[0m`)
      const result = await database
        .deleteFrom('list_records')
        .where('chain_id', '=', chainId.toString())
        .where('contract_address', '=', contractAddress)
        .where('nonce', '=', nonce.toString())
        .where('record', '=', listRecordHexstring)
        .executeTakeFirst()
      logger.log(result)
    }
  }

  async onOwnershipTransferred(event: Event): Promise<void> {
    if (event.eventParameters.eventName !== 'OwnershipTransferred') {
      return
    }

    // this was a new contract that got deployed and transferred
    // ownership to the owner
    const previousOwner = event.eventParameters.args['previousOwner']
    const newOwner = event.eventParameters.args['newOwner']
    if (previousOwner === '0x0000000000000000000000000000000000000000') {
      const contractsRow: Row<'contracts'> = {
        chain_id: event.chainId,
        address: event.contractAddress,
        name: event.contractName,
        owner: newOwner
      }
      logger.log(`\x1b[96mInsert ${event.contractName} contract into \`contracts\` table\x1b[0m`)
      await database.insertInto('contracts').values([contractsRow]).executeTakeFirst()
    } else {
      // contract ownership was transferred but the contract should already
      // be in the database

      // we will update the owner in the database
      logger.log(
        `\x1b[95mUpdating ${event.contractName} contract owner from ${previousOwner} to ${newOwner} in \`contracts\` table\x1b[0m`
      )
      await database
        .updateTable('contracts')
        .set({ owner: newOwner })
        .where('chain_id', '=', event.chainId.toString())
        .where('address', '=', event.contractAddress)
        .executeTakeFirst()
    }
  }
}
