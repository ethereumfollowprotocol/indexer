--migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_followers
-- Description: Counts the unique followers for each address in the
--              view_list_records_with_nft_manager_user_tags, groups the results by address,
--              and orders them by the number of unique followers in descending
--              order. Includes a LIMIT parameter to control the number of
--              returned rows. The function filters by version and type,
--              excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (text) and 'follower_count' (BIGINT),
--          representing each address and its count of unique followers.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_leaderboard_followers (limit_count BIGINT) RETURNS TABLE (address types.eth_address, followers_count BIGINT) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS followers_count
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
        v.has_mute_tag = FALSE
    GROUP BY
        v.record_data
    ORDER BY
        followers_count DESC,
        v.record_data ASC
    LIMIT limit_count;
END;
$$;



--migrate:down