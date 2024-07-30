--migrate:up
-------------------------------------------------------------------------------
-- Function: get_user_lists
-- Description: Retrieves all lists for a given address from the
--              efp_lists table.
-- Parameters:
--   - p_address (eth_address): The address for which to retrieve the lists.
-- Returns: The lists for the given address. Returns NULL if no lists are found.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_user_lists(p_address types.eth_address) RETURNS TABLE (
  efp_list_nft_token_id types.efp_list_nft_token_id
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
	-- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);

RETURN QUERY
    SELECT list.token_id as efp_list_nft_token_id
	FROM public.efp_lists as list
	WHERE list.user = normalized_addr
    OR list.manager = normalized_addr
    OR list.owner = normalized_addr;
END;
$$;


--migrate:down