--migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_mutes
-- Description: Leaderboard query for users with the most mutes.
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (types.eth_address) and 'mutes_count'
--          (BIGINT), representing each user and their count of unique
--          mutes addresses.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_leaderboard_mutes (limit_count BIGINT) RETURNS TABLE (address types.eth_address, mutes_count BIGINT) LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY
  SELECT
        v.user AS address,
        COUNT(DISTINCT v.record_data) AS mutes_count
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- NOT blocked
        v.has_block_tag = TRUE AND
        -- valid address format
        public.is_valid_address(v.record_data)
    GROUP BY
        v.user
    ORDER BY
        mutes_count DESC,
        v.user ASC
    LIMIT limit_count;
END;
$$;



--migrate:down