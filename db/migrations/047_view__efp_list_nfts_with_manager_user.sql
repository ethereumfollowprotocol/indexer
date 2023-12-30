-- migrate:up
-------------------------------------------------------------------------------
-- View: view_list_nfts_with_manager_user
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_nfts_with_manager_user AS
SELECT
  nft_locs.efp_list_nft_chain_id,
  nft_locs.efp_list_nft_contract_address,
  nft_locs.efp_list_nft_token_id,
  nfts.owner AS efp_list_nft_owner,
  nft_locs.efp_list_storage_location,
  nft_locs.efp_list_storage_location_version,
  nft_locs.efp_list_storage_location_type,
  nft_locs.efp_list_storage_location_chain_id,
  nft_locs.efp_list_storage_location_contract_address,
  nft_locs.efp_list_storage_location_nonce,
  lm_manager.value::TYPES.eth_address AS efp_list_manager,
  lm_user.value::TYPES.eth_address AS efp_list_user
FROM
  PUBLIC.view__efp_list_nfts AS nfts
  LEFT JOIN PUBLIC.view__efp_list_storage_locations AS nft_locs ON nft_locs.efp_list_nft_chain_id = nfts.chain_id
  AND nft_locs.efp_list_nft_contract_address = nfts.address
  AND nft_locs.efp_list_nft_token_id = nfts.token_id
  LEFT JOIN PUBLIC.view__efp_list_metadata AS lm_manager ON lm_manager.chain_id = nft_locs.efp_list_storage_location_chain_id
  AND lm_manager.contract_address = nft_locs.efp_list_storage_location_contract_address
  AND lm_manager.nonce = nft_locs.efp_list_storage_location_nonce
  AND lm_manager.key = 'manager'
  AND PUBLIC.is_valid_address (lm_manager.value)
  LEFT JOIN PUBLIC.view__efp_list_metadata AS lm_user ON lm_user.chain_id = nft_locs.efp_list_storage_location_chain_id
  AND lm_user.contract_address = nft_locs.efp_list_storage_location_contract_address
  AND lm_user.nonce = nft_locs.efp_list_storage_location_nonce
  AND lm_user.key = 'user'
  AND PUBLIC.is_valid_address (lm_user.value);



-- migrate:down
