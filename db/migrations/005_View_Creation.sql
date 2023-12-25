-- migrate:up
-- View Creation: Define all necessary views
CREATE VIEW public.list_nfts_view AS
SELECT
  nfts.*,
  lm.value AS list_user
FROM
  public.list_nfts AS nfts
  LEFT JOIN public.list_metadata AS lm ON lm.chain_id = nfts.list_storage_location_chain_id
  AND lm.contract_address = nfts.list_storage_location_contract_address
  AND lm.nonce = nfts.list_storage_location_nonce
  AND lm.key = 'user';

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

CREATE VIEW public.list_record_tags_extended_view AS
SELECT
  nft.token_id,
  nft.list_user,
  nft.list_storage_location_chain_id,
  nft.list_storage_location_contract_address,
  nft.list_storage_location_nonce,
  v.record,
  v.version,
  v.record_type,
  v.data,
  v.tags,
  CASE
    WHEN 'block' = ANY(v.tags) THEN TRUE
    ELSE FALSE
  END AS has_block_tag,
  CASE
    WHEN 'mute' = ANY(v.tags) THEN TRUE
    ELSE FALSE
  END AS has_mute_tag
FROM
  public.list_record_tags_view AS v
  LEFT JOIN public.list_nfts_view AS nft ON nft.list_storage_location_chain_id = v.chain_id
  AND nft.list_storage_location_contract_address = v.contract_address
  AND nft.list_storage_location_nonce = v.nonce;

-- migrate:down