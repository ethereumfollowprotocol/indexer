-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001__opcode_001
-- Description: Handles a list op version 1 opcode 1 (add record) by
--              inserting the record into the efp_list_records table.
--              If the record already exists, then this function will raise an
--              exception.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_slot (types.efp_list_storage_location_slot): The slot associated with
--                                                    the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001__opcode_001 (types.efp_list_op__v001__opcode_001):
--                           The operation data as a record.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001__opcode_001 (
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring,
  p_list_op__v001__opcode_001 types.efp_list_op__v001__opcode_001
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    list_record_hex types.hexstring;
    list_record types.efp_list_record;
BEGIN
    list_record_hex := public.hexlify(p_list_op__v001__opcode_001.record);
    list_record := public.decode__list_record(list_record_hex);

    -- if there's a conflict, then this will raise an exception
    INSERT INTO public.efp_list_records (
        chain_id,
        contract_address,
        slot,
        record,
        record_version,
        record_type,
        record_data
    )
    VALUES (
        p_chain_id,
        p_contract_address,
        p_slot,
        p_list_op__v001__opcode_001.record,
        list_record.version,
        list_record.record_type,
        list_record.data
    );
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp__v001__opcode_001
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp__v001__opcode_001 (
    p_chain_id BIGINT,
    p_contract_address types.eth_address,
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring,
    p_list_op__v001__opcode_001 types.efp_list_op__v001__opcode_001
  ) CASCADE;