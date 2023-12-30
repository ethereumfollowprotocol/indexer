-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_ops__record_tag
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_ops__record_tag AS
SELECT
  ops.chain_id,
  ops.contract_address,
  ops.nonce,
  ops.data,
  ops.opcode,
  ops.block_number,
  ops.transaction_index,
  ops.log_index,
  ops.sort_key,
  unpacked.list_record_bytea AS record,
  unpacked.tag
FROM
  PUBLIC.view__efp_list_ops ops,
  LATERAL (
    SELECT
      *
    FROM
      public.unpack__list_record_tag (ops.data)
  ) AS unpacked
WHERE
  ops.opcode = 3
  OR ops.opcode = 4;



-------------------------------------------------------------------------------
-- View: view__latest_record_tags
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__latest_record_tags AS
SELECT
  chain_id,
  contract_address,
  nonce,
  record,
  tag,
  MAX(sort_key) AS max_sort_key
FROM
  PUBLIC.view__efp_list_ops__record_tag
GROUP BY
  chain_id,
  contract_address,
  nonce,
  record,
  tag;



-------------------------------------------------------------------------------
-- View: view__efp_list_record_tags
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_record_tags AS
SELECT
  subquery.chain_id,
  subquery.contract_address,
  subquery.nonce,
  subquery.record,
  GET_BYTE(subquery.record, 0) AS record_version,
  GET_BYTE(subquery.record, 1) AS record_type,
  SUBSTRING(
    subquery.record
    FROM
      3
  ) AS record_data,
  subquery.tag,
  subquery.block_number,
  subquery.transaction_index,
  subquery.log_index
FROM
  (
    SELECT
      ops.chain_id,
      ops.contract_address,
      ops.nonce,
      ops.record,
      ops.tag,
      ops.block_number,
      ops.transaction_index,
      ops.log_index
    FROM
      PUBLIC.view__efp_list_ops__record_tag ops
      INNER JOIN PUBLIC.view__latest_record_tags max_records ON ops.chain_id = max_records.chain_id
      AND ops.contract_address = max_records.contract_address
      AND ops.nonce = max_records.nonce
      AND ops.record = max_records.record
      AND ops.tag = max_records.tag
      AND ops.sort_key = max_records.max_sort_key
    WHERE
      ops.opcode = 3
  ) AS subquery;



-- migrate:down
