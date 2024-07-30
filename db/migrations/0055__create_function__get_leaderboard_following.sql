--migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_following
-- Description: Counts the unique addresses that each user is following in the
--              view_list_records_with_nft_manager_user_tags, groups the
--              results by user, and orders them by the number of unique
--              addresses in descending order. Includes a LIMIT parameter to
--              control the number of returned rows. The function filters by
--              version and type, excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (types.eth_address) and 'following_count'
--          (BIGINT), representing each user and their count of unique
--          following addresses.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_leaderboard_following (limit_count BIGINT) RETURNS TABLE (address types.eth_address, following_count BIGINT) LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY
  SELECT
        v.user AS address,
        COUNT(DISTINCT v.record_data) AS following_count
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE AND
        -- valid address format
        public.is_valid_address(v.record_data)
    GROUP BY
        v.user
    ORDER BY
        following_count DESC,
        v.user ASC
    LIMIT limit_count;
END;
$$;



--migrate:down