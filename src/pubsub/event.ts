import { type Log, decodeEventLog } from 'viem'

export type Event = {
  chainId: bigint
  blockNumber: bigint
  blockHash: `0x${string}`
  contractAddress: `0x${string}`
  contractName: string
  transactionHash: `0x${string}`
  transactionIndex: number
  logIndex: number
  eventParameters: { eventName: string; args: Record<string, any> }
  data: string
  topics: string[]

  serializeArgs: () => string
  sortKey: () => string
}

export function decodeLogtoEvent(chainId: bigint, contractName: string, abi: any, log: Log): Event {
  const {
    address, // The address of the contract that produced the log.
    blockHash, // The hash of the block where this log was in.
    blockNumber, // The block number where this log was in.
    data, // The data contained in this log - often related to the event that triggered the log.
    logIndex, // The index of this log in the block.
    transactionHash, // The hash of the transaction that generated this log.
    transactionIndex, // The index of the transaction in the block.
    topics // Topics are used for indexing; first topic is usually the hash of the event signature.
  } = log

  // problem: we don't have ABI here
  // but I don't want to have to repeat this code for each contract
  const decodedTopics: { eventName: string; args: Record<string, any> } = decodeEventLog({
    abi,
    data,
    topics
  })

  if (
    blockNumber === null ||
    blockHash === null ||
    transactionHash === null ||
    transactionIndex === null ||
    logIndex === null
  ) {
    throw new Error('Cannot decode pending log')
  }

  return {
    chainId,
    blockNumber,
    blockHash,
    contractAddress: address,
    contractName,
    transactionHash,
    transactionIndex,
    logIndex,
    eventParameters: decodedTopics,
    data,
    topics,
    serializeArgs: () =>
      JSON.stringify(decodedTopics.args, (_: string, value: any) => {
        if (typeof value === 'bigint') {
          // 32-byte hex string
          return `0x${value.toString(16).padStart(64, '0')}`
        }
        return value
      }),
    // signature: () => createEventSignature(decodedTopics),
    sortKey: () =>
      `${blockNumber.toString().padStart(12, '0')}-${transactionIndex.toString().padStart(6, '0')}-${logIndex
        .toString()
        .padStart(6, '0')}`
  }
}

export type OrderableEventLog = {
  blockNumber: bigint | null
  transactionIndex: number | null
  logIndex: number | null
}

export function compareEvents(a: OrderableEventLog, b: OrderableEventLog): number {
  if (a.blockNumber === null || b.blockNumber === null) {
    throw new Error('blockNumber is null')
  }
  let result = Number(a.blockNumber - b.blockNumber)
  if (result !== 0) return result

  if (a.transactionIndex === null || b.transactionIndex === null) {
    throw new Error('transactionIndex is null')
  }
  result = a.transactionIndex - b.transactionIndex
  if (result !== 0) return result

  if (a.logIndex === null || b.logIndex === null) {
    throw new Error('Log index is null')
  }
  return a.logIndex - b.logIndex
}

export function createEventSignature(abiObject: any): `${string}(${string})` {
  if (abiObject === undefined) {
    throw new Error('abiObject is undefined')
  }
  const params = abiObject.inputs
    .map((input: any) => {
      return `${input.type}${input.indexed ? ' indexed' : ''} ${input.name}`
    })
    .join(', ')

  return `event ${abiObject.name}(${params})`
}
