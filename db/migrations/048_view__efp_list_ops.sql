-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_list_ops
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__efp_list_ops AS
SELECT
  PUBLIC.view__efp_list_op__events.*,
  decoded_op.version,
  decoded_op.opcode,
  decoded_op.data
FROM
  PUBLIC.view__efp_list_op__events,
  LATERAL (
    SELECT
      (PUBLIC.decode__efp_list_op (op)).*
  ) AS decoded_op (version, opcode, data);



-- migrate:down
