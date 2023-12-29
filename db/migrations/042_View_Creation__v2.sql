-- migrate:up
-------------------------------------------------------------------------------
-- View: view__contracts
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__contracts AS
SELECT
  chain_id,
  contract_address AS address,
  'TODO' AS NAME,
  PUBLIC.normalize_eth_address (event_args ->> 'newOwner') AS OWNER
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'OwnershipTransferred';



-------------------------------------------------------------------------------
-- View: view__account_metadata__events
-------------------------------------------------------------------------------
-- View for account metadata events
CREATE OR REPLACE VIEW PUBLIC.view__account_metadata__events AS
SELECT
  chain_id,
  block_number,
  transaction_index,
  log_index,
  contract_address,
  event_name,
  PUBLIC.normalize_eth_address (event_args ->> 'addr') AS address,
  event_args ->> 'key' AS KEY,
  event_args ->> 'value' AS VALUE
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'NewAccountMetadataValue';



-------------------------------------------------------------------------------
-- View: view__account_metadata
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__account_metadata AS
SELECT
  a.chain_id,
  a.contract_address,
  a.address,
  a.key,
  a.value,
  a.block_number,
  a.transaction_index,
  a.log_index
FROM
  PUBLIC.view__account_metadata__events a
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      address,
      KEY,
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS latest_sort_key
    FROM
      PUBLIC.view__account_metadata__events
    GROUP BY
      chain_id,
      contract_address,
      address,
      KEY
  ) b ON a.chain_id = b.chain_id
  AND a.contract_address = b.contract_address
  AND a.address = b.address
  AND a.key = b.key
  AND PUBLIC.sort_key (a.block_number, a.transaction_index, a.log_index) = b.latest_sort_key;



-------------------------------------------------------------------------------
-- View: view__list_metadata__events
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_metadata__events AS
SELECT
  chain_id,
  block_number,
  transaction_index,
  log_index,
  contract_address,
  event_name,
  (event_args ->> 'nonce')::TYPES.efp_list_storage_location_nonce AS nonce,
  event_args ->> 'key' AS KEY,
  event_args ->> 'value' AS VALUE
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'NewListMetadataValue';



-------------------------------------------------------------------------------
-- View: view__list_metadata
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_metadata AS
SELECT
  a.chain_id,
  a.contract_address,
  a.nonce,
  a.key,
  a.value,
  a.block_number,
  a.transaction_index,
  a.log_index
FROM
  PUBLIC.view__list_metadata__events a
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      nonce,
      KEY,
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS latest_sort_key
    FROM
      PUBLIC.view__list_metadata__events
    GROUP BY
      chain_id,
      contract_address,
      nonce,
      KEY
  ) b ON a.chain_id = b.chain_id
  AND a.contract_address = b.contract_address
  AND a.nonce = b.nonce
  AND a.key = b.key
  AND PUBLIC.sort_key (a.block_number, a.transaction_index, a.log_index) = b.latest_sort_key;



-------------------------------------------------------------------------------
-- View: view__list_op__events
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_op__events AS
SELECT
  chain_id,
  block_number,
  transaction_index,
  log_index,
  contract_address,
  event_name,
  (event_args ->> 'nonce')::TYPES.efp_list_storage_location_nonce AS nonce,
  event_args ->> 'op' AS op,
  PUBLIC.unhexlify (event_args ->> 'op') AS op_bytes
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'ListOp';



-------------------------------------------------------------------------------
-- View: view__list_ops
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_ops AS
SELECT
  PUBLIC.view__list_op__events.*,
  decoded_op.version,
  decoded_op.opcode,
  decoded_op.data
FROM
  PUBLIC.view__list_op__events,
  LATERAL (
    SELECT
      (PUBLIC.decode__efp_list_op (op)).*
  ) AS decoded_op (version, opcode, data);



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
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS max_sort_key
    FROM
      PUBLIC.view__list_ops
    WHERE
      -- find the last add/remove record op for each record
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
  AND PUBLIC.sort_key (
    vlo.block_number,
    vlo.transaction_index,
    vlo.log_index
  ) = max_records.max_sort_key
WHERE
  -- only include if last opcode was a add op
  vlo.opcode = 1;



-- migrate:down
