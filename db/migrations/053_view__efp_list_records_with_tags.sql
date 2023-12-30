-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_record_tags_agg
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__efp_list_records_with_tags AS
SELECT
  r.chain_id,
  r.contract_address,
  r.nonce,
  r.record,
  r.record_version,
  r.record_type,
  r.record_data,
  ARRAY_AGG(t.tag) FILTER (
    WHERE
      t.tag IS NOT NULL
  ) AS tags
FROM
  PUBLIC.view__efp_list_records r
  LEFT JOIN PUBLIC.view__efp_list_record_tags t ON r.chain_id = t.chain_id
  AND r.contract_address = t.contract_address
  AND r.nonce = t.nonce
  AND r.record = t.record
GROUP BY
  r.chain_id,
  r.contract_address,
  r.nonce,
  r.record,
  r.record_version,
  r.record_type,
  r.record_data;



-- migrate:down