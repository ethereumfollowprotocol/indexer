-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_contracts
-------------------------------------------------------------------------------
/*
 | View Name                      | Event Type Filtered            | Sub-Steps in Query Execution                                    | Influence on Index Structure                                | Index                                                        |
 |--------------------------------|--------------------------------|-----------------------------------------------------------------|-------------------------------------------------------------|--------------------------------------------------------------|
 | `view__events__efp_contracts`  | `OwnershipTransferred`         | 1. Filter on `OwnershipTransferred` events                      | Start index with `event_name` for filtering                 | Step 1: `(event_name)`                                       |
 |                                |                                | 2. Group by `chain_id` and `contract_address`                   | Add `chain_id` and `contract_address` for grouping          | Step 2: `(event_name, chain_id, contract_address)`           |
 |                                |                                | 3. Sort by `sort_key` within each group                         | Append `sort_key` for sorting                               | Step 3: `(event_name, chain_id, contract_address, sort_key)` |
 */
CREATE INDEX
  idx__efp_contracts_events__efp_contracts ON PUBLIC.events (chain_id, contract_address, sort_key)
WHERE
  event_name = 'OwnershipTransferred';



CREATE
OR REPLACE VIEW PUBLIC.view__events__efp_contracts AS
SELECT
  e.chain_id,
  e.contract_address AS address,
  -- Placeholder for contract name, to be implemented.
  'TODO' AS name,
  PUBLIC.normalize_eth_address (e.event_args ->> 'newOwner') AS owner
FROM
  PUBLIC.events e
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      -- latest event for each contract.
      MAX(sort_key) AS max_sort_key
    FROM
      PUBLIC.events
    WHERE
      event_name = 'OwnershipTransferred'
    GROUP BY
      chain_id,
      contract_address
  ) AS latest_events ON e.chain_id = latest_events.chain_id
  AND e.contract_address = latest_events.contract_address
  AND e.sort_key = latest_events.max_sort_key -- latest event for each contract.
WHERE
  -- Filters out only the 'OwnershipTransferred' events from the events table.
  e.event_name = 'OwnershipTransferred';



-- Comment on the view
COMMENT
  ON VIEW public.view__events__efp_contracts IS 'View to list the latest ownership details of EFP contracts.';



-- Comment on the columns
COMMENT
  ON COLUMN public.view__events__efp_contracts.chain_id IS 'Chain ID of the deployed contract.';



COMMENT
  ON COLUMN public.view__events__efp_contracts.address IS 'Contract address.';



COMMENT
  ON COLUMN public.view__events__efp_contracts.name IS 'Contract name.';



COMMENT
  ON COLUMN public.view__events__efp_contracts.owner IS 'Contract owner.';



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_contracts
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__events__efp_contracts CASCADE;