--migrate:up


-------------------------------------------------------------------------------
-- Function: get_unique_followers
-- Description: Retrieves a distinct list of followers for a specified address,
--              de-duplicating by 'list_user'. This ensures each follower is
--              listed once, even if associated with multiple tokens.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with 'list_user' (types.eth_address), representing unique
--          names or identifiers of the followers.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_unique_followers (p_address types.eth_address) RETURNS TABLE (efp_list_user types.eth_address) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);

    RETURN QUERY
    SELECT DISTINCT
        v.efp_list_user
    FROM
        public.view__efp_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.record_data) AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE AND
        -- match the address parameter
        v.record_data = public.unhexlify(normalized_addr)
    ORDER BY
        v.efp_list_user ASC;
END;
$$;


--migrate:down