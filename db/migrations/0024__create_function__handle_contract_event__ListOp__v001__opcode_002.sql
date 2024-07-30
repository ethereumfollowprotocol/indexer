-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_002
-- Description: Handles a list op version 1 opcode 2 (remove record) by
--              removing the record from the efp_list_records table.
--              If the record does not already exist, then this function will
--              raise an exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_slot (types.efp_list_storage_location_slot): The slot associated with
--                                                    the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_002 (types.efp_list_op__v001__opcode_002):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_002 (
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_002 types.efp_list_op__v001__opcode_002
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    -- if it doesn't already exist, raise exception
    IF NOT EXISTS (
        SELECT 1
        FROM public.efp_list_records
        WHERE
            chain_id = p_chain_id AND
            contract_address = p_contract_address AND
            slot = p_slot AND
            record = p_list_op__v001__opcode_002.record
    ) THEN
        -- RAISE WARNING 'Attempt to remove non-existent efp_list_records row (chain_id=%, contract_address=%, slot=%, record=%)',
        --     p_chain_id,
        --     p_contract_address,
        --     p_slot,
        --     list_record_hex;
        -- RAISE EXCEPTION 'Cannot remove non-existent efp_list_records row (chain_id=%, contract_address=%, slot=%, record=%)',
        --     p_chain_id,
        --     p_contract_address,
        --     p_slot,
        --     list_record_hex;
    END IF;

    -- the record exists, so delete it
    DELETE FROM public.efp_list_records
    WHERE
        chain_id = p_chain_id AND
        contract_address = p_contract_address AND
        slot = p_slot AND
        record = p_list_op__v001__opcode_002.record;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp__v001__opcode_002
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp__v001__opcode_002 (
    p_chain_id BIGINT,
    p_contract_address types.eth_address,
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring,
    p_list_op__v001__opcode_002 types.efp_list_op__v001__opcode_002
  ) CASCADE;