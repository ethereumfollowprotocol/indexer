--migrate:up
-------------------------------------------------------------------------------
-- Function: get_primary_list
-- Description: Retrieves the primary list value for a given address from the
--              account_metadata table. If not found, falls back to finding the
--              lowest token_id from view_list_nfts_with_manager_user where
--              list_user equals the address. Converts valid hex string values
--              to BIGINT.
-- Parameters:
--   - addr (types.eth_address): The address for which to retrieve the
--          primary list value.
-- Returns: The BIGINT representation of the primary list value for the given
--          address, or the lowest token_id from with list_user equals the
--          address. Returns NULL if no primary list value is found.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_primary_list (p_address types.eth_address) RETURNS BIGINT AS $$
DECLARE
    primary_list_token_id BIGINT;
BEGIN
    SELECT v.primary_list_token_id
    INTO primary_list_token_id
    FROM public.view__efp_accounts_with_primary_list AS v
    WHERE v.address = public.normalize_eth_address(p_address);

    RETURN primary_list_token_id;
END;
$$ LANGUAGE plpgsql;



--migrate:down