-- migrate:up



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_001
-- Description: Inserts a new record into the list_records table. This function
--              is responsible for decoding the record data and storing it in
--              the appropriate format.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated with
--                                        the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_op (types.hexstring): The operation data as a hex string.
--   - p_op_decoded (types.efp_list_op__v001__opcode_001): The operation data
--                                                         as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_001(
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_nonce BIGINT,
  p_op_hex types.hexstring,
  p_op_v001__opcode_001 types.efp_list_op__v001__opcode_001
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    list_record types.efp_list_record;
BEGIN
    list_record := public.decode_list_record(p_op_v001__opcode_001.record_hex);

    INSERT INTO public.list_records (chain_id, contract_address, nonce, record, version, record_type, data)
    VALUES (
        p_chain_id,
        p_contract_address,
        p_nonce,
        p_op_v001__opcode_001.record_hex,
        list_record.version,
        list_record.record_type,
        list_record.data_hex
    )
    ON CONFLICT (chain_id, contract_address, nonce, record) DO NOTHING;

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
--   - p_contract_address (types.eth_address): The contract address associated with
--                                        the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_op (types.hexstring): The operation data as a hex string.
--   - p_op_v001 (types.efp_list_op__v001): The operation data as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001(
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_nonce BIGINT,
  p_op_hex types.hexstring,
  p_op_v001 types.efp_list_op__v001
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    op_v001__opcode_001 types.efp_list_op__v001__opcode_001;
BEGIN
    CASE
        WHEN p_op_v001.opcode = 1 THEN
            op_v001__opcode_001 := (p_op_v001.version, p_op_v001.opcode::types.uint8__1, p_op_v001.data_hex)::types.efp_list_op__v001__opcode_001;
            PERFORM public.handle_contract_event__ListOp__v001__opcode_001(
              p_chain_id,
              p_contract_address,
              p_nonce,
              p_op_hex,
              op_v001__opcode_001
            );
        WHEN p_op_v001.opcode = 2 THEN
        -- skip
        WHEN p_op_v001.opcode = 3 THEN
        -- skip
        WHEN p_op_v001.opcode = 4 THEN
        -- skip
        ELSE
            RAISE EXCEPTION 'Unsupported list op version 1 opcode: %', p_op_v001.opcode;
    END CASE;
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
--   - p_op_hex (types.hexstring): The operation data as a hex string.
-- Returns: VOID
-- Notes: Uses the list_ops table for storage. Decoding functions are stubbed.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp(
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_nonce BIGINT,
  p_op_hex types.hexstring
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    op_decoded types.efp_list_op;
    op_v001 types.efp_list_op__v001;
BEGIN
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    op_decoded := public.decode_list_op(p_op_hex);

    -- Insert the operation into list_ops
    INSERT INTO public.list_ops (chain_id, contract_address, nonce, op, version, opcode, data)
    VALUES (p_chain_id, normalized_contract_address, p_nonce, p_op_hex, op_decoded.version, op_decoded.opcode, op_decoded.data_hex)
    ON CONFLICT (chain_id, contract_address, nonce, op) DO NOTHING;

    CASE
      WHEN op_decoded.version = 1 THEN
          op_v001 := (op_decoded.version::types.uint8__1, op_decoded.opcode, op_decoded.data_hex)::types.efp_list_op__v001;
          PERFORM public.handle_contract_event__ListOp__v001(
            p_chain_id,
            p_contract_address,
            p_nonce,
            p_op_hex,
            op_v001
          );
      ELSE
          RAISE EXCEPTION 'Unsupported list op version: %', op_decoded.version;
    END CASE;

END;
$$;



-- migrate:down
