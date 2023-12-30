-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_account_metadata__events
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__efp_account_metadata__events AS
SELECT
  chain_id,
  block_number,
  transaction_index,
  log_index,
  contract_address,
  event_name,
  PUBLIC.normalize_eth_address (event_args ->> 'addr') AS address,
  event_args ->> 'key' AS KEY,
  event_args ->> 'value' AS VALUE
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'NewAccountMetadataValue';



-- migrate:down