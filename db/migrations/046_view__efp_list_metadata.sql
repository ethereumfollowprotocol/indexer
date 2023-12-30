-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_metadata
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_metadata AS
SELECT
  e.chain_id,
  e.contract_address,
  (event_args ->> 'nonce')::TYPES.efp_list_storage_location_nonce AS nonce,
  e.event_args ->> 'key' AS key,
  e.event_args ->> 'value' AS value,
  e.block_number,
  e.transaction_index,
  e.log_index
FROM
  PUBLIC.contract_events e
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      event_args ->> 'nonce' AS nonce,
      event_args ->> 'key' AS key,
      MAX(sort_key) AS latest_sort_key
    FROM
      PUBLIC.contract_events
    WHERE
      event_name = 'UpdateListMetadata'
    GROUP BY
      chain_id,
      contract_address,
      event_args ->> 'nonce',
      event_args ->> 'key'
  ) latest ON e.chain_id = latest.chain_id
  AND e.contract_address = latest.contract_address
  AND e.event_args ->> 'nonce' = latest.nonce
  AND e.event_args ->> 'key' = latest.key
  AND e.sort_key = latest.latest_sort_key
WHERE
  e.event_name = 'UpdateListMetadata';



-- migrate:down
