-- migrate:up
-------------------------------------------------------------------------------
-- View: view_list_nfts_with_manager_user
-------------------------------------------------------------------------------
CREATE VIEW PUBLIC.view_list_nfts_with_manager_user AS
SELECT
  nfts.*,
  lm_manager.value::TYPES.eth_address AS list_manager,
  lm_user.value::TYPES.eth_address AS list_user
FROM
  PUBLIC.list_nfts AS nfts
  LEFT JOIN PUBLIC.list_metadata AS lm_manager ON lm_manager.chain_id = nfts.list_storage_location_chain_id
  AND lm_manager.contract_address = nfts.list_storage_location_contract_address
  AND lm_manager.nonce = nfts.list_storage_location_nonce
  AND lm_manager.key = 'manager'
  AND PUBLIC.is_valid_address (lm_manager.value)
  LEFT JOIN PUBLIC.list_metadata AS lm_user ON lm_user.chain_id = nfts.list_storage_location_chain_id
  AND lm_user.contract_address = nfts.list_storage_location_contract_address
  AND lm_user.nonce = nfts.list_storage_location_nonce
  AND lm_user.key = 'user'
  AND PUBLIC.is_valid_address (lm_user.value);



-------------------------------------------------------------------------------
-- View: view_list_records_with_tag_array
-------------------------------------------------------------------------------
CREATE VIEW PUBLIC.view_list_records_with_tag_array AS
SELECT
  records.chain_id,
  records.contract_address,
  records.nonce,
  records.record,
  records.version,
  records.record_type,
  records.data,
  ARRAY_AGG(tags.tag) AS tags
FROM
  PUBLIC.list_records AS records
  LEFT JOIN PUBLIC.list_record_tags AS tags ON tags.chain_id = records.chain_id
  AND tags.contract_address = records.contract_address
  AND tags.nonce = records.nonce
  AND tags.record = records.record
GROUP BY
  records.chain_id,
  records.contract_address,
  records.nonce,
  records.record,
  records.version,
  records.record_type,
  records.data;



-------------------------------------------------------------------------------
-- View: view_list_records_with_nft_manager_user_tags
-------------------------------------------------------------------------------
CREATE VIEW PUBLIC.view_list_records_with_nft_manager_user_tags AS
SELECT
  nfts.token_id,
  nfts.owner,
  nfts.list_manager,
  nfts.list_user,
  nfts.list_storage_location_chain_id,
  nfts.list_storage_location_contract_address,
  nfts.list_storage_location_nonce,
  record_tags.record,
  record_tags.version,
  record_tags.record_type,
  record_tags.data,
  record_tags.tags,
  CASE
    WHEN 'block' = ANY (record_tags.tags) THEN TRUE
    ELSE FALSE
  END AS has_block_tag,
  CASE
    WHEN 'mute' = ANY (record_tags.tags) THEN TRUE
    ELSE FALSE
  END AS has_mute_tag
FROM
  PUBLIC.view_list_records_with_tag_array AS record_tags
  LEFT JOIN PUBLIC.view_list_nfts_with_manager_user AS nfts ON nfts.list_storage_location_chain_id = record_tags.chain_id
  AND nfts.list_storage_location_contract_address = record_tags.contract_address
  AND nfts.list_storage_location_nonce = record_tags.nonce;



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
