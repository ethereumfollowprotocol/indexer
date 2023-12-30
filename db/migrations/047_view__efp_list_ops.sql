-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_ops
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_ops AS
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
      (event_args ->> 'nonce')::TYPES.efp_list_storage_location_nonce AS nonce,
      event_args ->> 'op' AS op,
      PUBLIC.unhexlify (event_args ->> 'op') AS op_bytes,
      block_number,
      transaction_index,
      log_index
    FROM
      PUBLIC.contract_events
    WHERE
      event_name = 'ListOp'
  ) AS list_op_events,
  LATERAL (
    SELECT
      (PUBLIC.decode__efp_list_op (op)).*
  ) AS decoded_op (version, opcode, data);



-- migrate:down
