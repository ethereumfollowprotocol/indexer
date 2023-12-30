-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_account_metadata
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_account_metadata AS
SELECT
  e.chain_id,
  e.contract_address,
  PUBLIC.normalize_eth_address (e.event_args ->> 'addr') AS address,
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
      event_args ->> 'addr' AS address,
      event_args ->> 'key' AS key,
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS latest_sort_key
    FROM
      PUBLIC.contract_events
    WHERE
      event_name = 'UpdateAccountMetadata'
    GROUP BY
      chain_id,
      contract_address,
      event_args ->> 'addr',
      event_args ->> 'key'
  ) latest ON e.chain_id = latest.chain_id
  AND e.contract_address = latest.contract_address
  AND e.event_args ->> 'addr' = latest.address
  AND e.event_args ->> 'key' = latest.key
  AND PUBLIC.sort_key (e.block_number, e.transaction_index, e.log_index) = latest.latest_sort_key
WHERE
  e.event_name = 'UpdateAccountMetadata';



-- migrate:down
