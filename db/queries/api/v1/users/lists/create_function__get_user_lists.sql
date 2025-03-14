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
    SELECT 
        l.token_id as efp_list_nft_token_id 
    FROM public.efp_lists l 
    JOIN public.efp_list_metadata m 
        ON m.chain_id = l.list_storage_location_chain_id
        AND m.contract_address = l.list_storage_location_contract_address
        AND m.slot = l.list_storage_location_slot
    WHERE ( 
        (m.key = 'user' OR m.key = 'manager') AND
        m.value = normalized_addr
    ) OR (
        l.owner = normalized_addr
    )
    GROUP BY token_id;
END;
$$;


--migrate:down