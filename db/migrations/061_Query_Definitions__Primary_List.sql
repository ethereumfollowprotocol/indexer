-- migrate:up
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
OR REPLACE FUNCTION query.get_primary_list (address types.eth_address) RETURNS BIGINT AS $$
DECLARE
    primary_list TEXT;
    normalized_addr types.eth_address;
    lowest_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(address);

    -- Retrieve the primary list value from account_metadata
    SELECT am.value INTO primary_list
    FROM public.account_metadata AS am
    WHERE am.address = normalized_addr AND am.key = 'efp.list.primary';

    -- Check if a primary list value was found and is valid
    IF primary_list IS NOT NULL THEN
        RETURN public.convert_hex_to_BIGINT(primary_list);
    END IF;

    -- Fallback: Retrieve the lowest token_id
    SELECT MIN(token_id) INTO lowest_token_id
    FROM view_list_nfts_with_manager_user
    WHERE list_user = normalized_addr;

    RETURN lowest_token_id;
END;
$$ LANGUAGE plpgsql;

-- migrate:down
