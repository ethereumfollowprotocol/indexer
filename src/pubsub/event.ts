import { type Log, decodeEventLog } from 'viem'

export type Event = {
  chainId: bigint
  transactionHash: `0x${string}`
  blockNumber: bigint
  contractAddress: `0x${string}`
  contractName: string
  eventParameters: { eventName: string; args: Record<string, any> }
  data: string
  topics: string[]
}

export function decodeLogtoEvent(chainId: bigint, contractName: string, abi: any, log: Log): Event {
  const { address, blockNumber, data, topics, transactionHash } = log
  // problem: we don't have ABI here
  // but I don't want to have to repeat this code for each contract
  const decodedTopics: { eventName: string; args: Record<string, any> } = decodeEventLog({
    abi,
    data,
    topics
  })

  if (transactionHash === null || blockNumber === null) {
    throw new Error('Cannot decode pending log')
  }

  return {
    chainId,
    transactionHash,
    blockNumber,
    contractAddress: address,
    contractName,
    eventParameters: decodedTopics,
    data,
    topics
  }
}
