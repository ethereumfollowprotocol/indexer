-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_list_records_with_nft_manager_user_tags
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_list_records_with_nft_manager_user_tags AS
SELECT
  nfts.efp_list_nft_chain_id,
  nfts.efp_list_nft_contract_address,
  nfts.efp_list_nft_token_id,
  nfts.efp_list_nft_owner,
  nfts.efp_list_manager,
  nfts.efp_list_user,
  nfts.efp_list_storage_location_chain_id,
  nfts.efp_list_storage_location_contract_address,
  nfts.efp_list_storage_location_slot,
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
  PUBLIC.view__events__efp_list_records_with_tags AS record_tags
  LEFT JOIN PUBLIC.view__events__efp_list_nfts_with_manager_user AS nfts ON nfts.efp_list_storage_location_chain_id = record_tags.chain_id
  AND nfts.efp_list_storage_location_contract_address = record_tags.contract_address
  AND nfts.efp_list_storage_location_slot = record_tags.slot;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_list_records_with_nft_manager_user_tags
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_list_records_with_nft_manager_user_tags CASCADE;