import { decodeEventLog, type Log } from 'viem'

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
    topics
  }
}
