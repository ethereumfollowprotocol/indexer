export type ListRecord = {
  version: number
  recordType: number
  data: Uint8Array
}

export function decodeListRecord(recordBytes: Uint8Array): ListRecord {
  const recordDataView = new DataView(recordBytes.buffer)
  const version: number = recordDataView.getUint8(0)
  const recordType: number = recordDataView.getUint8(1)
  const data: Uint8Array = recordBytes.slice(2)
  return {
    version,
    recordType,
    data
  }
}
