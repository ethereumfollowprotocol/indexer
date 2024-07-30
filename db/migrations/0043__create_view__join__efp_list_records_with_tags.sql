-- migrate:up
-------------------------------------------------------------------------------
-- View: view__join__efp_list_records_with_tags
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__join__efp_list_records_with_tags AS
SELECT
  r.chain_id,
  r.contract_address,
  r.slot,
  r.record,
  r.record_version,
  r.record_type,
  r.record_data,
  r.updated_at,
  ARRAY_AGG(t.tag) FILTER (
    WHERE
      t.tag IS NOT NULL
  ) AS tags
FROM
  PUBLIC.efp_list_records r
  LEFT JOIN PUBLIC.efp_list_record_tags t ON r.chain_id = t.chain_id
  AND r.contract_address = t.contract_address
  AND r.slot = t.slot
  AND r.record = t.record
GROUP BY
  r.chain_id,
  r.contract_address,
  r.slot,
  r.record,
  r.record_version,
  r.record_type,
  r.record_data;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__join__efp_list_records_with_tags
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__join__efp_list_records_with_tags CASCADE;