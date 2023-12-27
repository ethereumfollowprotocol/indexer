export type ListOp = {
  version: number
  opcode: number
  data: Uint8Array
}

export function decodeListOp(op: Uint8Array | `0x${string}`): ListOp {
  let opBytes: Uint8Array
  if (typeof op === 'string') {
    opBytes = Buffer.from(op.slice(2), 'hex')
  } else {
    opBytes = op
  }
  const opDataView = new DataView(opBytes.buffer)
  const version: number = opDataView.getUint8(0)
  const opcode: number = opDataView.getUint8(1)
  const data: Uint8Array = opBytes.slice(2)
  return {
    version,
    opcode,
    data
  }
}
