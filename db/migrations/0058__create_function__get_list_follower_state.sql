--migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_follower_state
-- Description: Retrieves the state of relationship between a list holder and  
--              address, whether the address is following, blocking or muting,
--              the list holder.
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
OR REPLACE FUNCTION query.get_list_follower_state(p_account_list_id INT, p_follower_address VARCHAR(42)) RETURNS TABLE (
  is_follower BOOLEAN,
  is_blocking BOOLEAN,
  is_muting BOOLEAN
) LANGUAGE plpgsql AS $$
DECLARE
    follower_addr types.eth_address;
    account_addr types.eth_address;
    follower_list_id BIGINT;
    lsl_chain_id BIGINT;
    lsl_contract_address VARCHAR(42);
    lsl_storage_slot types.efp_list_storage_location_slot;
BEGIN
	  follower_addr := public.normalize_eth_address(p_follower_address);
	-- Now determine the list storage location for the primary list token id
	SELECT v.user 
    INTO account_addr
    FROM efp_lists as v 
    WHERE token_id = p_account_list_id;

	SELECT v.token_id 
    INTO follower_list_id
    FROM efp_lists as v 
    WHERE v.user = follower_addr;


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
      v.efp_list_nft_token_id = follower_list_id;
	RETURN QUERY

	SELECT 
		-- NOT (record.has_block_tag OR record.has_mute_tag) AS is_following,
  --   	record.has_block_tag AS is_blocked,
  --   	record.has_mute_tag AS is_muted
		COALESCE(NOT (record.has_block_tag OR record.has_mute_tag), FALSE) AS is_follower,
		COALESCE(record.has_block_tag, FALSE) AS is_blocking,
		COALESCE(record.has_mute_tag, FALSE) AS is_muting
	FROM public.view__join__efp_list_records_with_nft_manager_user_tags as record
	WHERE 
		lsl_storage_slot = record.list_storage_location_slot AND
		lsl_contract_address = record.list_storage_location_contract_address AND
		lsl_chain_id = record.list_storage_location_chain_id AND
		hexlify(record_data) = account_addr AND
		token_id = follower_list_id;
END;
$$;



--migrate:down