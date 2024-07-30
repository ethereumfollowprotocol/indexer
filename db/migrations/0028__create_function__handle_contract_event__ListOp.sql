-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp
-- Description: Inserts a new operation record into the list_ops table. This
--              function is responsible for decoding the operation data and
--              storing it in the appropriate format.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the operation.
--   - p_slot (BIGINT): The slot associated with the operation.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
-- Returns: VOID
-- Notes: Uses the efp_list_ops table for storage. Decoding functions are
--        stubbed.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    list_op types.efp_list_op;
    list_op__v001 types.efp_list_op__v001;
BEGIN
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    list_op := public.decode__efp_list_op(p_list_op_hex);

    -- Insert the operation into list_ops
    INSERT INTO public.efp_list_ops (
        chain_id,
        contract_address,
        slot,
        op,
        version,
        opcode,
        data
    )
    VALUES (
        p_chain_id,
        normalized_contract_address,
        p_slot,
        p_list_op_hex,
        list_op.version,
        list_op.opcode,
        public.hexlify(list_op.data)
    )
    ON CONFLICT (chain_id, contract_address, slot, op) DO NOTHING;

    -- Handle the operation
    CASE list_op.version
      WHEN 1 THEN
          list_op__v001 := (
              list_op.version::types.uint8__1,
              list_op.opcode,
              list_op.data
          )::types.efp_list_op__v001;
          PERFORM public.handle_contract_event__ListOp__v001(
            p_chain_id,
            p_contract_address,
            p_slot,
            p_list_op_hex,
            list_op__v001
          );
      ELSE
          RAISE EXCEPTION 'Unsupported list op version: %', list_op.version;
    END CASE;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring
  ) CASCADE;