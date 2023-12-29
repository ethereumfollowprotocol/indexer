-- migrate:up
-------------------------------------------------------------------------------
-- View: view__list_op__events
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__list_op__events AS
SELECT
  chain_id,
  block_number,
  transaction_index,
  log_index,
  contract_address,
  event_name,
  (event_args ->> 'nonce')::TYPES.efp_list_storage_location_nonce AS nonce,
  event_args ->> 'op' AS op,
  PUBLIC.unhexlify (event_args ->> 'op') AS op_bytes
FROM
  PUBLIC.contract_events
WHERE
  event_name = 'ListOp';



-- migrate:down
