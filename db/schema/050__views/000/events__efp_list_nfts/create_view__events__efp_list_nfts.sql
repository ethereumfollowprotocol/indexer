-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_list_nfts
-------------------------------------------------------------------------------
/*
 | View Name                      | Event Type Filtered            | Sub-Steps in Query Execution                                         | Influence on Index Structure                                                  | Index                                                                                    |
 |--------------------------------|--------------------------------|----------------------------------------------------------------------|-------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
 | `view__events__efp_list_nfts`  | `Transfer`                     | 1. Filter on `Transfer` events                                       | Start index with `event_name` for filtering                                   | Step 1: `(event_name)`                                                                   |
 |                                |                                | 2. Group by `chain_id`, `contract_address`, `event_args->>'tokenId'` | Add `chain_id`, `contract_address`, and `event_args->>'tokenId'` for grouping | Step 2: `(event_name, chain_id, contract_address, (event_args ->> 'tokenId'))`           |
 |                                |                                | 3. Sort by `sort_key` within each group                              | Append `sort_key` for sorting                                                 | Step 3: `(event_name, chain_id, contract_address, (event_args ->> 'tokenId'), sort_key)` |
 */
CREATE INDEX
  idx__efp_events__efp_list_nfts ON PUBLIC.events (
    chain_id,
    contract_address,
    (event_args ->> 'tokenId'),
    sort_key
  )
WHERE
  event_name = 'Transfer';



CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_list_nfts AS
SELECT
  e.chain_id,
  e.contract_address,
  (event_args ->> 'tokenId') :: BIGINT AS token_id,
  PUBLIC.normalize_eth_address (e.event_args ->> 'to') AS owner
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
      event_name = 'Transfer'
    GROUP BY
      chain_id,
      contract_address,
      event_args ->> 'tokenId'
  ) AS latest_events ON e.chain_id = latest_events.chain_id
  AND e.contract_address = latest_events.contract_address
  AND e.event_args ->> 'tokenId' = latest_events.token_id
  AND e.sort_key = latest_events.max_sort_key
WHERE
  e.event_name = 'Transfer';



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_list_nfts
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_list_nfts CASCADE;