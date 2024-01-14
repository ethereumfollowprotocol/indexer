--migrate:up
-------------------------------------------------------------------------------
-- Function: get_followers
-- Description: Retrieves a list of followers for a specified address from the
--              view_list_records_with_nft_manager_user_tags. It filters tokens by version and
--              type, excluding blocked or muted relationships.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with
--            'efp_list_nft_token_id' (types.efp_list_nft_token_id),
--            'follower' (types.eth_address),
--             tags (types.efp_tag []),
--          representing the list token ID, list user, and tags.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_followers (p_address types.eth_address) RETURNS TABLE (
  efp_list_nft_token_id types.efp_list_nft_token_id,
  follower types.eth_address,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- the token id that follows the <p_address>
        v.token_id AS efp_list_nft_token_id,
        -- the list user of the EFP List that follows the <p_address>
        v.user AS follower,
        v.tags
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
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
        -- who follow the address
        -- (the "data" of the address record is the address that is followed)
        v.record_data = public.unhexlify(p_address)
    ORDER BY
        v.token_id ASC;
END;
$$;



--migrate:down