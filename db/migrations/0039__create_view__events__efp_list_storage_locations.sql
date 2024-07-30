-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_list_storage_location
-------------------------------------------------------------------------------
/*
 | View Name                                  | Event Type Filtered            | Sub-Steps in Query Execution                                         | Influence on Index Structure                                                      | Index Building Progress                                                                  |
 |--------------------------------------------|--------------------------------|----------------------------------------------------------------------|-----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
 | `view__events__efp_list_storage_locations` | `UpdateListStorageLocation`    | 1. Filter on `UpdateListStorageLocation` events                      | Start index with `event_name` for filtering                                       | Step 1: `(event_name)`                                                                   |
 |                                            |                                | 2. Group by `chain_id`, `contract_address`, `event_args->>'tokenId'` | Add `chain_id`, `contract_address`, and `event_args->>'tokenId'` for grouping     | Step 2: `(event_name, chain_id, contract_address, (event_args ->> 'tokenId'))`           |
 |                                            |                                | 3. Sort by `sort_key` within each group                              | Append `sort_key` for sorting                                                     | Step 3: `(event_name, chain_id, contract_address, (event_args ->> 'tokenId'), sort_key)` |
 */
CREATE INDEX
  idx__efp_events__list_storage_locations ON PUBLIC.events (
    chain_id,
    contract_address,
    (event_args ->> 'tokenId'),
    sort_key
  )
WHERE
  event_name = 'UpdateListStorageLocation';



CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_list_storage_locations AS
SELECT
  subquery.efp_list_nft_chain_id,
  subquery.efp_list_nft_contract_address,
  subquery.efp_list_nft_token_id,
  subquery.efp_list_storage_location,
  subquery.version AS efp_list_storage_location_version,
  subquery.location_type AS efp_list_storage_location_type,
  subquery.chain_id AS efp_list_storage_location_chain_id,
  subquery.contract_address AS efp_list_storage_location_contract_address,
  subquery.slot AS efp_list_storage_location_slot
FROM
  (
    SELECT
      e.chain_id AS efp_list_nft_chain_id,
      e.contract_address AS efp_list_nft_contract_address,
      (event_args ->> 'tokenId') :: bigint AS efp_list_nft_token_id,
      PUBLIC.unhexlify (e.event_args ->> 'listStorageLocation') AS efp_list_storage_location,
      (
        PUBLIC.decode__efp_list_storage_location__v001__location_type_001 (e.event_args ->> 'listStorageLocation')
      ).*
    FROM
      PUBLIC.events e
      INNER JOIN (
        SELECT
          chain_id,
          contract_address,
          event_args ->> 'tokenId' AS token_id,
          MAX(sort_key) AS max_sort_key
        FROM
          PUBLIC.events
        WHERE
          event_name = 'UpdateListStorageLocation'
        GROUP BY
          chain_id,
          contract_address,
          event_args ->> 'tokenId'
      ) AS latest_events ON e.chain_id = latest_events.chain_id
      AND e.contract_address = latest_events.contract_address
      AND e.event_args ->> 'tokenId' = latest_events.token_id
      AND e.sort_key = latest_events.max_sort_key
    WHERE
      e.event_name = 'UpdateListStorageLocation'
  ) subquery;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_list_storage_locations
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_list_storage_locations CASCADE;