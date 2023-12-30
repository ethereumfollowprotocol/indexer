-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_nfts
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_nfts AS
SELECT
  e.chain_id,
  e.contract_address AS address,
  event_args ->> 'tokenId' AS token_id,
  PUBLIC.normalize_eth_address (e.event_args ->> 'to') AS owner
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
      event_name = 'Transfer'
    GROUP BY
      chain_id,
      contract_address,
      event_args ->> 'tokenId'
  ) AS latest_events ON e.chain_id = latest_events.chain_id
  AND e.contract_address = latest_events.contract_address
  AND e.event_args ->> 'tokenId' = latest_events.token_id
  AND PUBLIC.sort_key (e.block_number, e.transaction_index, e.log_index) = latest_events.max_sort_key
WHERE
  e.event_name = 'Transfer';



-- migrate:down
