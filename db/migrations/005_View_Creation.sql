-- migrate:up
-------------------------------------------------------------------------------
-- View: list_nfts_view
-------------------------------------------------------------------------------
CREATE VIEW public.list_nfts_view AS
SELECT
  nfts.*,
  lm_user.value AS list_user,
  lm_manager.value AS list_manager
FROM
  public.list_nfts AS nfts
  LEFT JOIN public.list_metadata AS lm_user ON lm_user.chain_id = nfts.list_storage_location_chain_id
  AND lm_user.contract_address = nfts.list_storage_location_contract_address
  AND lm_user.nonce = nfts.list_storage_location_nonce
  AND lm_user.key = 'user'
  AND public.is_valid_address(lm_user.value)
  LEFT JOIN public.list_metadata AS lm_manager ON lm_manager.chain_id = nfts.list_storage_location_chain_id
  AND lm_manager.contract_address = nfts.list_storage_location_contract_address
  AND lm_manager.nonce = nfts.list_storage_location_nonce
  AND lm_manager.key = 'manager'
  AND public.is_valid_address(lm_manager.value);

-------------------------------------------------------------------------------
-- View: list_record_tags_view
-------------------------------------------------------------------------------
CREATE VIEW public.list_record_tags_view AS
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
-- View: list_record_tags_extended_view
-------------------------------------------------------------------------------
CREATE VIEW public.list_record_tags_extended_view AS
SELECT
  nftv.token_id,
  nftv.owner,
  nftv.list_manager,
  nftv.list_user,
  nftv.list_storage_location_chain_id,
  nftv.list_storage_location_contract_address,
  nftv.list_storage_location_nonce,
  lrtv.record,
  lrtv.version,
  lrtv.record_type,
  lrtv.data,
  lrtv.tags,
  CASE
    WHEN 'block' = ANY(lrtv.tags) THEN TRUE
    ELSE FALSE
  END AS has_block_tag,
  CASE
    WHEN 'mute' = ANY(lrtv.tags) THEN TRUE
    ELSE FALSE
  END AS has_mute_tag
FROM
  public.list_record_tags_view AS lrtv
  LEFT JOIN public.list_nfts_view AS nftv ON nftv.list_storage_location_chain_id = lrtv.chain_id
  AND nftv.list_storage_location_contract_address = lrtv.contract_address
  AND nftv.list_storage_location_nonce = lrtv.nonce;

-- migrate:down