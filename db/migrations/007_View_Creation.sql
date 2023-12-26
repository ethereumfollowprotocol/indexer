-- migrate:up
-------------------------------------------------------------------------------
-- View: view_list_nfts_with_manager_user
-------------------------------------------------------------------------------
CREATE VIEW public.view_list_nfts_with_manager_user AS
SELECT
  nfts.*,
  lm_manager.value :: types.eth_address AS list_manager,
  lm_user.value :: types.eth_address AS list_user
FROM
  public.list_nfts AS nfts
  LEFT JOIN public.list_metadata AS lm_manager ON lm_manager.chain_id = nfts.list_storage_location_chain_id
  AND lm_manager.contract_address = nfts.list_storage_location_contract_address
  AND lm_manager.nonce = nfts.list_storage_location_nonce
  AND lm_manager.key = 'manager'
  AND public.is_valid_address(lm_manager.value)
  LEFT JOIN public.list_metadata AS lm_user ON lm_user.chain_id = nfts.list_storage_location_chain_id
  AND lm_user.contract_address = nfts.list_storage_location_contract_address
  AND lm_user.nonce = nfts.list_storage_location_nonce
  AND lm_user.key = 'user'
  AND public.is_valid_address(lm_user.value);

-------------------------------------------------------------------------------
-- View: view_list_records_with_tag_array
-------------------------------------------------------------------------------
CREATE VIEW public.view_list_records_with_tag_array AS
SELECT
  records.chain_id,
  records.contract_address,
  records.nonce,
  records.record,
  records.version,
  records.record_type,
  records.data,
  array_agg(tags.tag) AS tags
FROM
  public.list_records AS records
  LEFT JOIN public.list_record_tags AS tags ON tags.chain_id = records.chain_id
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
CREATE VIEW public.view_list_records_with_nft_manager_user_tags AS
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
    WHEN 'block' = ANY(record_tags.tags) THEN TRUE
    ELSE FALSE
  END AS has_block_tag,
  CASE
    WHEN 'mute' = ANY(record_tags.tags) THEN TRUE
    ELSE FALSE
  END AS has_mute_tag
FROM
  public.view_list_records_with_tag_array AS record_tags
  LEFT JOIN public.view_list_nfts_with_manager_user AS nfts ON nfts.list_storage_location_chain_id = record_tags.chain_id
  AND nfts.list_storage_location_contract_address = record_tags.contract_address
  AND nfts.list_storage_location_nonce = record_tags.nonce;

-- migrate:down