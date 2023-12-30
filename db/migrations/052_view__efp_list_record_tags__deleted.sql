-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_record_tags__deleted
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__efp_list_record_tags__deleted AS
SELECT
  vlo.chain_id,
  vlo.contract_address,
  vlo.nonce,
  vlo.record,
  GET_BYTE(vlo.record, 0) AS record_version,
  GET_BYTE(vlo.record, 1) AS record_type,
  SUBSTRING(
    vlo.record
    FROM
      3
  ) AS record_data,
  vlo.tag,
  vlo.block_number,
  vlo.transaction_index,
  vlo.log_index
FROM
  PUBLIC.view__efp_list_ops__record_tag vlo
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      nonce,
      record,
      tag,
      -- aggregate opcodes into an array for holistic checks
      ARRAY_AGG(opcode) AS opcodes,
      -- order by block_number, transaction_index, log_index
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS max_sort_key
    FROM
      PUBLIC.view__efp_list_ops__record_tag
    WHERE
      opcode = 3
      OR opcode = 4
    GROUP BY
      chain_id,
      contract_address,
      nonce,
      record,
      tag
    HAVING
      -- Filter groups to include only those that have an 'add' operation (opcode 3)
      3 = ANY (ARRAY_AGG(opcode))
  ) AS max_records ON vlo.chain_id = max_records.chain_id
  AND vlo.contract_address = max_records.contract_address
  AND vlo.nonce = max_records.nonce
  AND vlo.record = max_records.record
  AND vlo.tag = max_records.tag
  AND PUBLIC.sort_key (
    vlo.block_number,
    vlo.transaction_index,
    vlo.log_index
  ) = max_records.max_sort_key
WHERE
  -- Only return records/tags where last operation was opcode 4 (remove record/tag)
  vlo.opcode = 4;



-- migrate:down