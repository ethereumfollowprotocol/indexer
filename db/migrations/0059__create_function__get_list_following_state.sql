--migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_following_state
-- Description: Retrieves the state of relationship between a list holder and  
--              address, whether the list is following, blocking or muting,
--              the address.
-- Parameters:
--   - list_id (INT): The primary list id used to identify and filter followers.
-- Returns: A table with
--            'follower' (types.eth_address),
--            'efp_list_nft_token_id' (types.efp_list_nft_token_id),
--             tags (types.efp_tag []),
--            'is_following' (BOOLEAN),
--            'is_blocked' (BOOLEAN),
--            'is_muted' (BOOLEAN),
--          representing the list token ID, list user, and tags.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_following_state (p_token_id INT, p_address types.eth_address) RETURNS TABLE (
    is_following BOOLEAN,
	is_blocked BOOLEAN,
	is_muted BOOLEAN
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
    lsl_chain_id BIGINT;
    lsl_contract_address VARCHAR(42);
    lsl_storage_slot types.efp_list_storage_location_slot;
BEGIN
	  normalized_addr := public.normalize_eth_address(p_address);
	-- Now determine the list storage location for the primary list token id
    
	SELECT
      v.efp_list_storage_location_chain_id,
      v.efp_list_storage_location_contract_address,
      v.efp_list_storage_location_slot
    INTO
      lsl_chain_id,
      lsl_contract_address,
      lsl_storage_slot
    FROM
      public.view__events__efp_list_storage_locations AS v
    WHERE
      v.efp_list_nft_token_id = p_token_id;
	RETURN QUERY

	SELECT 
		-- NOT (record.has_block_tag OR record.has_mute_tag) AS is_following,
  --   	record.has_block_tag AS is_blocked,
  --   	record.has_mute_tag AS is_muted
		COALESCE(NOT (record.has_block_tag OR record.has_mute_tag), FALSE) AS is_following,
		COALESCE(record.has_block_tag, FALSE) AS is_blocked,
		COALESCE(record.has_mute_tag, FALSE) AS is_muted
	FROM public.view__join__efp_list_records_with_nft_manager_user_tags as record
	WHERE 
		lsl_storage_slot = record.list_storage_location_slot AND
		lsl_contract_address = record.list_storage_location_contract_address AND
		lsl_chain_id = record.list_storage_location_chain_id AND
		hexlify(record_data) = normalized_addr AND
		token_id = p_token_id;
END;
$$;


--migrate:down