-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_list_records
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_list_records AS
SELECT
  ops.chain_id,
  ops.contract_address,
  ops.slot,
  ops.data as record,
  GET_BYTE(ops.data, 0) :: types.uint8 AS record_version,
  GET_BYTE(ops.data, 1) :: types.uint8 AS record_type,
  SUBSTRING(
    ops.data
    FROM
      3
  ) AS record_data,
  ops.block_number,
  ops.transaction_index,
  ops.log_index
FROM
  PUBLIC.view__events__efp_list_ops ops
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      slot,
      data as record,
      -- order by block_number, transaction_index, log_index
      -- This helps in identifying the latest operation for each unique record
      MAX(sort_key) AS max_sort_key
    FROM
      PUBLIC.view__events__efp_list_ops
    WHERE
      -- restrict to opcodes 1 (add record) or 2 (remove record)
      opcode = 1
      OR opcode = 2
    GROUP BY
      chain_id,
      contract_address,
      slot,
      data
  ) AS max_records ON ops.chain_id = max_records.chain_id
  AND ops.contract_address = max_records.contract_address
  AND ops.slot = max_records.slot
  AND ops.data = max_records.record
  AND ops.sort_key = max_records.max_sort_key
WHERE
  -- Only return records where last operation was opcode 2 (remove record)
  opcode = 1;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_list_records
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_list_records CASCADE;