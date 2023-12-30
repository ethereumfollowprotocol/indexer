-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_contracts
-------------------------------------------------------------------------------
-- Creating a view to list the latest ownership details of Ethereum contracts
CREATE OR REPLACE VIEW PUBLIC.view__efp_contracts AS -- Selects the necessary columns to represent a contract and its latest owner.
-- The view filters and presents data from the 'contract_events' table,
-- focusing specifically on 'OwnershipTransferred' events, which indicate
-- changes in contract ownership.
SELECT
  e.chain_id,
  e.contract_address AS address,
  'TODO' AS name,
  -- Placeholder for contract name, to be implemented.
  PUBLIC.normalize_eth_address (e.event_args ->> 'newOwner') AS owner -- The source table containing all contract events.
FROM
  PUBLIC.contract_events e -- Joining with a subquery to ensure we only get the latest ownership event
  -- for each contract.
  INNER JOIN (
    -- This subquery identifies the latest 'OwnershipTransferred' event for each
    -- contract (identified by chain_id and contract_address) using a sort key.
    SELECT
      chain_id,
      contract_address,
      -- The MAX function combined with the custom sort_key function determines
      -- the latest event by considering the block number, transaction index, and log index.
      MAX(sort_key) AS max_sort_key
    FROM
      PUBLIC.contract_events
    WHERE
      event_name = 'OwnershipTransferred' -- Grouping by contract and chain ID to calculate the latest event for each.
    GROUP BY
      chain_id,
      contract_address
  ) AS latest_events ON e.chain_id = latest_events.chain_id
  AND e.contract_address = latest_events.contract_address -- Ensures that we only consider the latest 'OwnershipTransferred' event
  -- for each contract.
  AND e.sort_key = latest_events.max_sort_key -- Filters out only the 'OwnershipTransferred' events from the contract_events table.
WHERE
  e.event_name = 'OwnershipTransferred';



-- Comment on the view
COMMENT ON VIEW public.view__efp_contracts IS 'View to list the latest ownership details of EFP contracts.';



-- Comment on the columns
COMMENT ON COLUMN public.view__efp_contracts.chain_id IS 'Chain ID of the deployed contract.';



COMMENT ON COLUMN public.view__efp_contracts.address IS 'Contract address.';



COMMENT ON COLUMN public.view__efp_contracts.name IS 'Contract name.';



COMMENT ON COLUMN public.view__efp_contracts.owner IS 'Contract owner.';



-- migrate:down
