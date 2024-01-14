-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_003
-- Description: Handles a list op version 1 opcode 3 (add record tag) by
--              inserting the record tag into the efp_list_record_tags table.
--              If the record tag already exists, then this function will raise
--              an exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_slot (types.efp_list_storage_location_slot): The slot associated with
--                                                    the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_003 (types.efp_list_op__v001__opcode_003):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_003 (
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_003 types.efp_list_op__v001__opcode_003
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    -- if there's a conflict, then this will raise an exception
    INSERT INTO public.efp_list_record_tags (
        chain_id,
        contract_address,
        slot,
        record,
        tag
    )
    VALUES (
        p_chain_id,
        p_contract_address,
        p_slot,
        p_list_op__v001__opcode_003.record,
        p_list_op__v001__opcode_003.tag
    );
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp__v001__opcode_003
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp__v001__opcode_003 (
    p_chain_id BIGINT,
    p_contract_address types.eth_address,
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring,
    p_list_op__v001__opcode_003 types.efp_list_op__v001__opcode_003
  ) CASCADE;