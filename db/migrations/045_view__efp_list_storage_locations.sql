-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_storage_location
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_storage_locations AS
SELECT
  subquery.efp_list_nft_chain_id,
  subquery.efp_list_nft_contract_address,
  subquery.efp_list_nft_token_id,
  subquery.efp_list_storage_location,
  subquery.version AS list_storage_location_version,
  subquery.location_type AS list_storage_location_type,
  subquery.chain_id AS list_storage_location_chain_id,
  subquery.contract_address AS list_storage_location_contract_address,
  subquery.nonce AS list_storage_location_nonce
FROM
  (
    SELECT
      e.chain_id AS efp_list_nft_chain_id,
      e.contract_address AS efp_list_nft_contract_address,
      event_args ->> 'tokenId' AS efp_list_nft_token_id,
      PUBLIC.unhexlify (e.event_args ->> 'listStorageLocation') AS efp_list_storage_location,
      (
        PUBLIC.decode__efp_list_storage_location__v001__location_type_001 (e.event_args ->> 'listStorageLocation')
      ).*
    FROM
      PUBLIC.contract_events e
      INNER JOIN (
        SELECT
          chain_id,
          contract_address,
          event_args ->> 'tokenId' AS token_id,
          MAX(
            PUBLIC.sort_key (block_number, transaction_index, log_index)
          ) AS max_sort_key
        FROM
          PUBLIC.contract_events
        WHERE
          event_name = 'UpdateListStorageLocation'
        GROUP BY
          chain_id,
          contract_address,
          event_args ->> 'tokenId'
      ) AS latest_events ON e.chain_id = latest_events.chain_id
      AND e.contract_address = latest_events.contract_address
      AND e.event_args ->> 'tokenId' = latest_events.token_id
      AND PUBLIC.sort_key (e.block_number, e.transaction_index, e.log_index) = latest_events.max_sort_key
    WHERE
      e.event_name = 'UpdateListStorageLocation'
  ) subquery;



-- migrate:down
