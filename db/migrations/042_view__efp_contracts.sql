-- migrate:up
-------------------------------------------------------------------------------
-- View: view__contracts
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__contracts AS
SELECT
  chain_id,
  contract_address AS address,
  'TODO' AS NAME,
  PUBLIC.normalize_eth_address (event_args ->> 'newOwner') AS OWNER
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'OwnershipTransferred';



-- migrate:down
