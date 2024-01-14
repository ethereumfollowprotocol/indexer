-- migrate:up
-------------------------------------------------------------------------------
-- View: view__join__efp_list_records_with_nft_manager_user_tags
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__join__efp_list_records_with_nft_manager_user_tags AS
SELECT
  l.nft_chain_id,
  l.nft_contract_address,
  l.token_id,
  l.owner,
  l.manager,
  l.user,
  l.list_storage_location_chain_id,
  l.list_storage_location_contract_address,
  l.list_storage_location_slot,
  record_tags.record,
  record_tags.record_version,
  record_tags.record_type,
  record_tags.record_data,
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
  PUBLIC.view__join__efp_list_records_with_tags AS record_tags
  LEFT JOIN PUBLIC.efp_lists AS l ON l.list_storage_location_chain_id = record_tags.chain_id
  AND l.list_storage_location_contract_address = record_tags.contract_address
  AND l.list_storage_location_slot = record_tags.slot;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__join__efp_list_records_with_nft_manager_user_tags
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__join__efp_list_records_with_nft_manager_user_tags CASCADE;