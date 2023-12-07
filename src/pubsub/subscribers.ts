import {
  EFPAccountMetadataABI,
  EFPListMetadataABI,
  EFPListMinterABI,
  EFPListRecordsABI,
  EFPListRegistryABI
} from '#/abi'
import { database, type Row } from '#/database'
import { logger } from '#/logger'
import { decodeListOp, type ListOp } from '#/process/list-op'
import { decodeListRecord, type ListRecord } from '#/process/list-record'
import { timestamp } from '#/utilities'
import type { Abi } from 'viem'
import type { Event } from './event'

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

export class EFPListMetadataSubscriber extends ContractEventSubscriber {
  constructor(address: `0x${string}`) {
    super('EFPListMetadata', EFPListMetadataABI, address)
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
      await this.onTransfer(event)
    } else if (event.contractName === 'EFPAccountMetadata' && eventName === 'ValueSet') {
      await this.onAccountMetadataValueSet(event)
    } else if (event.contractName === 'EFPListMetadata' && eventName === 'ValueSet') {
      await this.onListMetadataValueSet(event)
    }
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
      chain_id: 1,
      contract_address: event.contractAddress,
      address: address,
      key: key,
      value: value
    }
    logger.log(`Account ${address} insert ${key}=${value} into \`account_metadata\` table`)

    // check if value is already set for this chain_id/contract_address/address/key
    const existing = await database
      .selectFrom('account_metadata')
      .where('chain_id', '=', '1')
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
        .where('chain_id', '=', '1')
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
    if (event.contractName !== 'EFPListMetadata' || event.eventParameters.eventName !== 'ValueSet') {
      return
    }

    const token_id: bigint = event.eventParameters.args['tokenId']
    const key: string = event.eventParameters.args['key']
    const value: string = event.eventParameters.args['value']

    // insert or update
    const row: Row<'list_metadata'> = {
      chain_id: 1,
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
      chain_id: 1,
      contract_address: event.contractAddress,
      nonce: nonce,
      op: op,
      version: opVersion,
      code: opCode,
      data: opDataHexstring
    }
    logger.log(`\x1b[96mInsert list op ${op} into \`list_ops\` table for nonce ${nonce}\x1b[0m`)
    await database.insertInto('list_ops').values([row]).executeTakeFirst()

    await this.processListOp(event.contractAddress, nonce, listOp)
  }

  async processListOp(contractAddress: `0x${string}`, nonce: bigint, listOp: ListOp): Promise<void> {
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
        chain_id: 1,
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
        .where('chain_id', '=', '1')
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
        chain_id: 1,
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
        .where('chain_id', '=', '1')
        .where('address', '=', event.contractAddress)
        .executeTakeFirst()
    }
  }

  async onTransfer(event: Event): Promise<void> {
    if (event.eventParameters.eventName !== 'Transfer') {
      return
    }

    const from: string = event.eventParameters.args['from']
    const to: string = event.eventParameters.args['to']
    if (from === '0x0000000000000000000000000000000000000000') {
      // insert as new row
      const row: Row<'list_nfts'> = {
        chain_id: 1,
        address: event.contractAddress,
        token_id: event.eventParameters.args['tokenId'],
        owner: to
      }

      logger.log(`\x1b[94mInsert ${event.eventParameters.eventName} event \`list_nfts\` table\x1b[0m`)
      await database.insertInto('list_nfts').values([row]).executeTakeFirst()
    } else {
      // update existing row
      logger.log(`\x1b[93mUpdate ${event.eventParameters.eventName} event in db\x1b[0m`)
      await database
        .updateTable('list_nfts')
        .set({ owner: to })
        .where('chain_id', '=', '1')
        .where('address', '=', event.contractAddress)
        .where('token_id', '=', event.eventParameters.args['tokenId'])
        .executeTakeFirst()
    }
  }
}
