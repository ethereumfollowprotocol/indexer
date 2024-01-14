-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_list_metadata
-------------------------------------------------------------------------------
/*
 | View Name                         | Event Type Filtered       | Sub-Steps in Query Execution                                        | Influence on Index Structure                                                    | Index Building Progress                                                                                        |
 |-----------------------------------|---------------------------|---------------------------------------------------------------------|---------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
 | `view__events__efp_list_metadata` | `UpdateListMetadata`      | 1. Filter on `UpdateListMetadata` events                            | Start index with `event_name` for filtering                                     | Step 1: `(event_name)`                                                                                         |
 |                                   |                           | 2. Group by `chain_id`, `contract_address`, `event_args->>'slot'`, `event_args->>'key'` | Add `chain_id`, `contract_address`, and specific `event_args` fields for grouping | Step 2: `(event_name, chain_id, contract_address, (event_args ->> 'slot'), (event_args ->> 'key'))`            |
 |                                   |                           | 3. Sort by `sort_key` within each group                             | Append `sort_key` for sorting                                                   | Step 3: `(event_name, chain_id, contract_address, (event_args ->> 'slot'), (event_args ->> 'key'), sort_key)`  |
 */
CREATE INDEX
  idx__efp_events__list_metadata ON PUBLIC.events (
    chain_id,
    contract_address,
    (event_args ->> 'slot'),
    (event_args ->> 'key'),
    sort_key
  )
WHERE
  event_name = 'UpdateListMetadata';



CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_list_metadata AS
SELECT
  e.chain_id,
  e.contract_address,
  DECODE(
    SUBSTRING(
      (event_args ->> 'slot')
      FROM
        3
    ),
    'hex'
  ) :: TYPES.efp_list_storage_location_slot AS slot,
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
      event_args ->> 'slot' AS slot,
      event_args ->> 'key' AS key,
      MAX(sort_key) AS latest_sort_key
    FROM
      PUBLIC.events
    WHERE
      event_name = 'UpdateListMetadata'
    GROUP BY
      chain_id,
      contract_address,
      event_args ->> 'slot',
      event_args ->> 'key'
  ) latest ON e.chain_id = latest.chain_id
  AND e.contract_address = latest.contract_address
  AND e.event_args ->> 'slot' = latest.slot
  AND e.event_args ->> 'key' = latest.key
  AND e.sort_key = latest.latest_sort_key
WHERE
  e.event_name = 'UpdateListMetadata';



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_list_metadata
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_list_metadata CASCADE;