--migrate:up
-------------------------------------------------------------------------------
-- Function: get_primary_list
-- Description: Retrieves the primary list value for a given address from the
--              account_metadata table. If not found, falls back to finding the
--              lowest token_id from view_list_nfts_with_manager_user where
--              list_user equals the address. Converts valid hex string values
--              to BIGINT.
-- Parameters:
--   - addr (VARCHAR(42)): The address for which to retrieve the primary list.
-- Returns: The BIGINT representation of the primary list value for the given
--          address, or the lowest token_id from with list_user equals the
--          address. Returns NULL if no primary list value is found.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_primary_list (p_address VARCHAR(42)) RETURNS BIGINT AS $$
DECLARE
    primary_list_token_id BIGINT;
BEGIN
    -- SELECT v.primary_list_token_id
    -- INTO primary_list_token_id
    -- FROM public.view__events__efp_accounts_with_primary_list AS v
    -- WHERE v.address = public.normalize_eth_address(p_address);

    -- RETURN primary_list_token_id;
    SELECT 
        l.token_id 
    INTO primary_list_token_id
    FROM public.efp_lists l 
    JOIN public.efp_list_metadata m 
        ON m.chain_id = l.list_storage_location_chain_id
        AND m.contract_address = l.list_storage_location_contract_address
        AND m.slot = l.list_storage_location_slot,
    efp_account_metadata meta
    WHERE meta.address::text = m.value::text 
        AND meta.key = 'primary-list'
        AND convert_hex_to_bigint(meta.value::text) = l.token_id::bigint
        AND meta.address = public.normalize_eth_address(p_address)
    GROUP BY l.token_id;
    RETURN primary_list_token_id;
END;
$$ LANGUAGE plpgsql;



--migrate:down