-- migrate:up
-------------------------------------------------------------------------------
-- View: view__list_records
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_records AS
SELECT
  vlo.chain_id,
  vlo.contract_address,
  vlo.nonce,
  vlo.data as record,
  GET_BYTE(vlo.data, 0) AS record_version,
  GET_BYTE(vlo.data, 1) AS record_type,
  SUBSTRING(
    vlo.data
    FROM
      3
  ) AS record_data,
  vlo.block_number,
  vlo.transaction_index,
  vlo.log_index
FROM
  PUBLIC.view__list_ops vlo
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      nonce,
      data as record,
      -- order by block_number, transaction_index, log_index
      -- This helps in identifying the latest operation for each unique record
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS max_sort_key
    FROM
      PUBLIC.view__list_ops
    WHERE
      -- restrict to opcodes 1 (add record) or 2 (remove record)
      opcode = 1
      OR opcode = 2
    GROUP BY
      chain_id,
      contract_address,
      nonce,
      data
  ) AS max_records ON vlo.chain_id = max_records.chain_id
  AND vlo.contract_address = max_records.contract_address
  AND vlo.nonce = max_records.nonce
  AND vlo.data = max_records.record
  AND PUBLIC.sort_key (
    vlo.block_number,
    vlo.transaction_index,
    vlo.log_index
  ) = max_records.max_sort_key
WHERE
  -- Only return records where last operation was opcode 2 (remove record)
  opcode = 1;



-- migrate:down
