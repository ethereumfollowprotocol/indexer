-- migrate:up



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_001
-- Description: Handles a list op version 1 opcode 1 (add record) by
--              inserting the record into the list_records table.
--              If the record already exists, then this function will raise an
--              exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_001 (types.efp_list_op__v001__opcode_002):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION
public.handle_contract_event__ListOp__v001__opcode_001(
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_nonce BIGINT,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_001 types.efp_list_op__v001__opcode_001
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    list_record types.efp_list_record;
BEGIN
    list_record := public.decode_list_record(
        p_list_op__v001__opcode_001.record_hex
    );

    -- if there's a conflict, then this will raise an exception
    INSERT INTO public.list_records (
        chain_id,
        contract_address,
        nonce, record,
        version,
        record_type,
        data
    )
    VALUES (
        p_chain_id,
        p_contract_address,
        p_nonce,
        p_list_op__v001__opcode_001.record_hex,
        list_record.version,
        list_record.record_type,
        list_record.data_hex
    );
END;
$$;



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_002
-- Description: Handles a list op version 1 opcode 2 (remove record) by
--              removing the record from the list_records table.
--              If the record does not already exist, then this function will
--              raise an exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_002 (types.efp_list_op__v001__opcode_002):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION
public.handle_contract_event__ListOp__v001__opcode_002(
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_nonce BIGINT,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_002 types.efp_list_op__v001__opcode_002
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    list_record types.efp_list_record;
BEGIN
    list_record := public.decode_list_record(p_list_op__v001__opcode_002.record_hex);

    -- if it doesn't already exist, raise exception
    IF NOT EXISTS (
        SELECT 1
        FROM public.list_records
        WHERE
            chain_id = p_chain_id AND
            contract_address = p_contract_address AND
            nonce = p_nonce AND
            record = p_list_op__v001__opcode_002.record_hex
    ) THEN
        RAISE EXCEPTION 'Cannot remove non-existent list_records row (chain_id=%, contract_address=%, nonce=%, record=%)',
            p_chain_id,
            p_contract_address,
            p_nonce,
            p_list_op__v001__opcode_002.record_hex;
    END IF;

    -- the record exists, so delete it
    DELETE FROM public.list_records
    WHERE
        chain_id = p_chain_id AND
        contract_address = p_contract_address AND
        nonce = p_nonce AND
        record = p_list_op__v001__opcode_002.record_hex;
END;
$$;



-- TODO: handle_contract_event__ListOp__v001__opcode_003
-- TODO: handle_contract_event__ListOp__v001__opcode_004



-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001
-- Description: TODO write description
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                        with the event.
--   - p_nonce (BIGINT): The nonce associated with the event.
--   - p_op (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001 (types.efp_list_op__v001): The operation data as a
--                                                 record.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001(
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_nonce BIGINT,
  p_list_op_hex types.hexstring,
  p_list_op__v001 types.efp_list_op__v001
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    list_op_v001__opcode_001 types.efp_list_op__v001__opcode_001;
    list_op_v001__opcode_002 types.efp_list_op__v001__opcode_002;
BEGIN
    CASE
        WHEN p_list_op__v001.opcode = 1 THEN
            list_op_v001__opcode_001 := (
                p_list_op__v001.version,
                p_list_op__v001.opcode::types.uint8__1,
                p_list_op__v001.data_hex
            )::types.efp_list_op__v001__opcode_001;
            PERFORM public.handle_contract_event__ListOp__v001__opcode_001(
              p_chain_id,
              p_contract_address,
              p_nonce,
              p_list_op_hex,
              list_op_v001__opcode_001
            );
        WHEN p_list_op__v001.opcode = 2 THEN
            list_op_v001__opcode_002 := (
              p_list_op__v001.version,
              p_list_op__v001.opcode::types.uint8__2,
              p_list_op__v001.data_hex
            )::types.efp_list_op__v001__opcode_002;
            PERFORM public.handle_contract_event__ListOp__v001__opcode_002(
              p_chain_id,
              p_contract_address,
              p_nonce,
              p_list_op_hex,
              list_op_v001__opcode_002
            );
        WHEN p_list_op__v001.opcode = 3 THEN
        -- skip
        WHEN p_list_op__v001.opcode = 4 THEN
        -- skip
        ELSE
            RAISE EXCEPTION 'Unsupported list op version 1 opcode: %',
                p_list_op__v001.opcode;
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
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
-- Returns: VOID
-- Notes: Uses the list_ops table for storage. Decoding functions are stubbed.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__ListOp(
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_nonce BIGINT,
  p_list_op_hex types.hexstring
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    list_op types.efp_list_op;
    list_op__v001 types.efp_list_op__v001;
BEGIN
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    list_op := public.decode_list_op(p_list_op_hex);

    -- Insert the operation into list_ops
    INSERT INTO public.list_ops (
        chain_id,
        contract_address,
        nonce,
        op,
        version,
        opcode,
        data
    )
    VALUES (
        p_chain_id,
        normalized_contract_address,
        p_nonce,
        p_list_op_hex,
        list_op.version,
        list_op.opcode,
        list_op.data_hex
    )
    ON CONFLICT (chain_id, contract_address, nonce, op) DO NOTHING;

    CASE
      WHEN list_op.version = 1 THEN
          list_op__v001 := (
              list_op.version::types.uint8__1,
              list_op.opcode, list_op.data_hex
          )::types.efp_list_op__v001;
          PERFORM public.handle_contract_event__ListOp__v001(
            p_chain_id,
            p_contract_address,
            p_nonce,
            p_list_op_hex,
            list_op__v001
          );
      ELSE
          RAISE EXCEPTION 'Unsupported list op version: %', list_op.version;
    END CASE;

END;
$$;



-- migrate:down
