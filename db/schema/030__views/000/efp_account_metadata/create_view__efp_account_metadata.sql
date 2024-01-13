-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_account_metadata
-------------------------------------------------------------------------------
/*
 | View Name                            | Event Type Filtered            | Sub-Steps in Query Execution                                                            | Influence on Index Structure                                                      | Index                                                                                                         |
 |--------------------------------------|--------------------------------|-----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
 | `view__events__efp_account_metadata` | `UpdateAccountMetadata`        | 1. Filter on `UpdateAccountMetadata` events                                             | Start index with `event_name` for filtering                                       | Step 1: `(event_name)`                                                                                        |
 |                                      |                                | 2. Group by `chain_id`, `contract_address`, `event_args->>'addr'`, `event_args->>'key'` | Add `chain_id`, `contract_address`, and specific `event_args` fields for grouping | Step 2: `(event_name, chain_id, contract_address, (event_args ->> 'addr'), (event_args ->> 'key'))`           |
 |                                      |                                | 3. Sort by `sort_key` within each group                                                 | Append `sort_key` for sorting                                                     | Step 3: `(event_name, chain_id, contract_address, (event_args ->> 'addr'), (event_args ->> 'key'), sort_key)` |
 */
CREATE INDEX
  idx__efp_events__efp_account_metadata ON PUBLIC.events (
    chain_id,
    contract_address,
    (event_args ->> 'addr'),
    (event_args ->> 'key'),
    sort_key
  )
WHERE
  event_name = 'UpdateAccountMetadata';



CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_account_metadata AS
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
  PUBLIC.events e
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      event_args ->> 'addr' AS address,
      event_args ->> 'key' AS key,
      MAX(sort_key) AS latest_sort_key
    FROM
      PUBLIC.events
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
  AND e.sort_key = latest.latest_sort_key
WHERE
  e.event_name = 'UpdateAccountMetadata';



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_account_metadata
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_account_metadata CASCADE;