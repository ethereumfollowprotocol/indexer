--migrate:up
-------------------------------------------------------------------------------
-- Function: get_unique_followers
-- Description: Retrieves a distinct list of followers for a specified address,
--              de-duplicating by 'list_user'. This ensures each follower is
--              listed once, even if associated with multiple tokens.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with
--            'follower' (types.eth_address),
--            'efp_list_nft_token_id' (types.efp_list_nft_token_id),
--             tags (types.efp_tag []),
--          representing the list token ID, list user, and tags.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_unique_followers(p_address types.eth_address) RETURNS TABLE (
  follower types.eth_address,
  efp_list_nft_token_id types.efp_list_nft_token_id,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    addr_bytea bytea;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);
    addr_bytea := public.unhexlify(normalized_addr);

    RETURN QUERY
    SELECT
        v.user AS follower,
        v.token_id AS efp_list_nft_token_id,
        COALESCE(v.tags, '{}') AS tags
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- match the address parameter
        v.record_data = addr_bytea AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE
    GROUP BY
        v.user,
        v.token_id,
        v.record_version,
        v.record_type,
        v.record_data,
        v.tags
    HAVING
        (SELECT get_primary_list FROM query.get_primary_list(v.user)) = v.token_id
    ORDER BY
        v.user ASC;
END;
$$;



--migrate:down