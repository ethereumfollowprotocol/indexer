-- migrate:up



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_001
-- Description: Inserts a new record into the list_records table. This function
--              is responsible for decoding the record data and storing it in
--              the appropriate format.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_op (types.hexstring): The operation data as a hex string.
--   - p_op_decoded (RECORD): The operation data as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_001(
  p_chain_id BIGINT,
  p_contract_address types.hexstring,
  p_nonce BIGINT,
  p_op types.hexstring,
    /*
    version SMALLINT,
    opcode SMALLINT,
    data types.hexstring
    */
  p_op_decoded RECORD
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Decode the record data
    -- TODO: Insert the operation into list_records
    -- INSERT INTO public.list_records (chain_id, contract_address, nonce, record, version, record_type, data)
    -- VALUES (p_chain_id, p_contract_address, p_nonce, foo.record, bar.version, baz.record_type, qux.data)
    -- ON CONFLICT (chain_id, contract_address, nonce, record) DO NOTHING;

    -- TODO: handle conflict (duplicate add record)
    -- RAISE EXCEPTION 'Unimplemented handle_contract_event__ListOp__v001__opcode_001';
END;
$$;


-- TODO: handle_contract_event__ListOp__v001__opcode_002
-- TODO: handle_contract_event__ListOp__v001__opcode_003
-- TODO: handle_contract_event__ListOp__v001__opcode_004



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001
-- Description: TODO write description
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_op (types.hexstring): The operation data as a hex string.
--   - p_op_decoded (RECORD): The operation data as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001(
  p_chain_id BIGINT,
  p_contract_address types.hexstring,
  p_nonce BIGINT,
  p_op types.hexstring,
    /*
    version SMALLINT,
    opcode SMALLINT,
    data types.hexstring
    */
  p_op_decoded RECORD
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- CASE
    --     WHEN p_op_decoded.opcode = 1 THEN
    --         PERFORM public.handle_contract_event__ListOp__v001__opcode_001(p_chain_id, p_contract_address, p_nonce, p_op, p_op_decoded);
    --     ELSE
    --         RAISE EXCEPTION 'Unsupported list op version 1 opcode: %', p_op_decoded.opcode;
    -- END CASE;
END;
$$;



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp
-- Description: Inserts a new operation record into the list_ops table. This
--              function is responsible for decoding the operation data and
--              storing it in the appropriate format.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the operation.
--   - p_nonce (BIGINT): The nonce associated with the operation.
--   - p_op (VARCHAR(255)): The operation data as a hex string.
-- Returns: VOID
-- Notes: Uses the list_ops table for storage. Decoding functions are stubbed.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp(
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_nonce BIGINT,
  p_op types.hexstring
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    /*
    version SMALLINT,
    opcode SMALLINT,
    data types.hexstring
    */
    op_decoded RECORD;
BEGIN
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    op_decoded := public.decode_list_op(p_op);

    -- Insert the operation into list_ops
    INSERT INTO public.list_ops (chain_id, contract_address, nonce, op, version, opcode, data)
    VALUES (p_chain_id, normalized_contract_address, p_nonce, p_op, op_decoded.version, op_decoded.opcode, op_decoded.data)
    ON CONFLICT (chain_id, contract_address, nonce, op) DO NOTHING;

    CASE
      WHEN op_decoded.version = 1 THEN
        PERFORM public.handle_contract_event__ListOp__v001(p_chain_id, p_contract_address, p_nonce, p_op, op_decoded);
      ELSE
        RAISE EXCEPTION 'Unsupported list op version: %', op_decoded.version;
    END CASE;

END;
$$;



-- migrate:down
