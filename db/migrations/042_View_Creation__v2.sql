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
  event_args ->> 'op' AS op
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'ListOp';



-- migrate:down
