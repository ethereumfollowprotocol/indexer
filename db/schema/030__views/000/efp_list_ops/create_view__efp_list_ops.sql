-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_ops
-------------------------------------------------------------------------------
/*
 | View Name                  | Event Type Filtered | Sub-Steps in Query Execution                           | Influence on Index Structure                                   | Index Building Progress                                                 |
 |----------------------------|---------------------|--------------------------------------------------------|---------------------------------------------------------------|-------------------------------------------------------------------------|
 | `view__efp_list_ops`       | `ListOp`            | 1. Filter on `ListOp` events                           | Start index with `event_name` for filtering                   | Step 1: `(event_name)`                                                  |
 |                            |                     | 2. Project `chain_id`, `contract_address`, `nonce`, `op`, and other relevant fields | Include `chain_id`, `contract_address`, and `event_args` fields for efficient data retrieval | Step 2: `(event_name, chain_id, contract_address, (event_args ->> 'nonce'), (event_args ->> 'op'))` |
 |                            |                     |                                                        |                                                               |                                                                          |
 */
CREATE INDEX
  idx__efp_events__list_ops ON PUBLIC.events (
    chain_id,
    contract_address,
    (event_args ->> 'nonce'),
    (event_args ->> 'op')
  )
WHERE
  event_name = 'ListOp';



CREATE
OR REPLACE VIEW PUBLIC.view__efp_list_ops AS
SELECT
  list_op_events.*,
  decoded_op.version,
  decoded_op.opcode,
  decoded_op.data
FROM
  (
    SELECT
      chain_id,
      contract_address,
      event_name,
      (event_args ->> 'nonce') :: TYPES.efp_list_storage_location_nonce AS nonce,
      event_args ->> 'op' AS op,
      PUBLIC.unhexlify (event_args ->> 'op') AS op_bytes,
      block_number,
      transaction_index,
      log_index,
      sort_key
    FROM
      PUBLIC.events
    WHERE
      event_name = 'ListOp'
  ) AS list_op_events,
  LATERAL (
    SELECT
      (PUBLIC.decode__efp_list_op (op)).*
  ) AS decoded_op (version, opcode, data);



-- migrate:down