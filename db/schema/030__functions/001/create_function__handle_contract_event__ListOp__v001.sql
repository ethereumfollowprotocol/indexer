-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__ListOp__v001
-- Description: TODO write description
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (types.eth_address): The contract address associated
--                                             with the event.
--   - p_slot (types.efp_list_storage_location_slot): The slot associated with
--                                                    the event.
--   - p_list_op_hex (types.hexstring): The operation data as a hex string.
--   - p_list_op__v001 (types.efp_list_op__v001): The operation data as a
--                                                record.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__ListOp__v001 (
  p_chain_id BIGINT,
  p_contract_address types.eth_address,
  p_slot types.efp_list_storage_location_slot,
  p_list_op_hex types.hexstring,
  p_list_op__v001 types.efp_list_op__v001
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    pair_list_record_tag RECORD;
BEGIN
    CASE p_list_op__v001.opcode
        WHEN 1 THEN
			IF LENGTH(p_list_op__v001.data) = 22 THEN
	            PERFORM public.handle_contract_event__ListOp__v001__opcode_001(
	              p_chain_id,
	              p_contract_address,
	              p_slot,
	              p_list_op_hex,
	              (
	                  p_list_op__v001.version,
	                  p_list_op__v001.opcode::types.uint8__1,
	                  p_list_op__v001.data
	              )::types.efp_list_op__v001__opcode_001
	            );
			END IF;
        WHEN 2 THEN
			IF LENGTH(p_list_op__v001.data) = 22 THEN
	            PERFORM public.handle_contract_event__ListOp__v001__opcode_002(
	              p_chain_id,
	              p_contract_address,
	              p_slot,
	              p_list_op_hex,
	              (
	                  p_list_op__v001.version,
	                  p_list_op__v001.opcode::types.uint8__2,
	                  p_list_op__v001.data
	              )::types.efp_list_op__v001__opcode_002
	            );
			END IF;
        WHEN 3 THEN
			IF LENGTH(p_list_op__v001.data) > 22 THEN
	            pair_list_record_tag := public.unpack__list_record_tag(
	              p_list_op__v001.data
	            );
	            PERFORM public.handle_contract_event__ListOp__v001__opcode_003(
	              p_chain_id,
	              p_contract_address,
	              p_slot,
	              p_list_op_hex,
	              (
	                  p_list_op__v001.version,
	                  p_list_op__v001.opcode::types.uint8__3,
	                  pair_list_record_tag.list_record_bytea,
	                  pair_list_record_tag.tag
	              )::types.efp_list_op__v001__opcode_003
	            );
			END IF;
        WHEN 4 THEN
			IF LENGTH(p_list_op__v001.data) > 22 THEN
	            pair_list_record_tag := public.unpack__list_record_tag(
	              p_list_op__v001.data
	            );
	            PERFORM public.handle_contract_event__ListOp__v001__opcode_004(
	              p_chain_id,
	              p_contract_address,
	              p_slot,
	              p_list_op_hex,
	              (
	                  p_list_op__v001.version,
	                  p_list_op__v001.opcode::types.uint8__4,
	                  pair_list_record_tag.list_record_bytea,
	                  pair_list_record_tag.tag
	              )::types.efp_list_op__v001__opcode_004
	            );
			END IF;
        ELSE
            RAISE EXCEPTION 'Unsupported list op version 1 opcode: %',
                p_list_op__v001.opcode;
    END CASE;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__ListOp__v001
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__ListOp__v001 (
    p_chain_id BIGINT,
    p_contract_address types.eth_address,
    p_slot types.efp_list_storage_location_slot,
    p_list_op_hex types.hexstring,
    p_list_op__v001 types.efp_list_op__v001
  ) CASCADE;