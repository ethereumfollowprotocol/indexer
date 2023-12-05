export type ListOp = {
  version: number
  code: number
  data: Uint8Array
}

export function decodeListOp(opBytes: Uint8Array): ListOp {
  const opDataView = new DataView(opBytes.buffer)
  const version: number = opDataView.getUint8(0)
  const code: number = opDataView.getUint8(1)
  const data: Uint8Array = opBytes.slice(2)
  return {
    version,
    code,
    data
  }
}
