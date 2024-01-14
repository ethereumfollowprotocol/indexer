-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_004
-- Description: Handles a list op version 1 opcode 4 (remove record tag) by
--              removing the record tag from the efp_list_record_tags table.
--              If the record tag does not already exist, then this function will
--              raise an exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_slot (types.efp_list_storage_location_slot): The slot associated with
--                                                    the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_004 (types.efp_list_op__v001__opcode_004):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_004 (
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_004 types.efp_list_op__v001__opcode_004
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    -- Check if the record tag exists
    IF NOT EXISTS (
        SELECT 1
        FROM public.efp_list_record_tags
        WHERE
            chain_id = p_chain_id AND
            contract_address = p_contract_address AND
            slot = p_slot AND
            record = p_list_op__v001__opcode_004.record AND
            tag = p_list_op__v001__opcode_004.tag
    ) THEN
        -- RAISE WARNING 'Attempt to remove non-existent efp_list_record_tags row (chain_id=%, contract_address=%, slot=%, record=%, tag=%)',
        --     p_chain_id,
        --     p_contract_address,
        --     p_slot,
        --     public.hexlify(p_list_op__v001__opcode_004.record),
        --     p_list_op__v001__opcode_004.tag;
        -- RAISE EXCEPTION 'Cannot remove non-existent efp_list_record_tags row (chain_id=%, contract_address=%, slot=%, record=%, tag=%)',
        --     p_chain_id,
        --     p_contract_address,
        --     p_slot,
        --     public.hexlify(p_list_op__v001__opcode_004.record),
        --     p_list_op__v001__opcode_004.tag;
    END IF;

    -- Record tag exists, so delete it
    DELETE FROM public.efp_list_record_tags
    WHERE
        chain_id = p_chain_id AND
        contract_address = p_contract_address AND
        slot = p_slot AND
        record = p_list_op__v001__opcode_004.record AND
        tag = p_list_op__v001__opcode_004.tag;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp__v001__opcode_004
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp__v001__opcode_004 (
    p_chain_id BIGINT,
    p_contract_address types.eth_address,
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring,
    p_list_op__v001__opcode_004 types.efp_list_op__v001__opcode_004
  ) CASCADE;