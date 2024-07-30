--migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_blocked
-- Description: Most blocked users
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (types.eth_address) and
--          'blocked_or_muted_count' (BIGINT), representing each address and
--          its count of unique followers.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_leaderboard_blocked_or_muted (limit_count BIGINT) RETURNS TABLE (
  address types.eth_address,
  blocked_or_muted_count BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS blocked_or_muted_count
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.record_data) AND
        -- blocked or muted
        (v.has_block_tag = TRUE OR v.has_mute_tag = TRUE)
    GROUP BY
        v.record_data
    ORDER BY
        blocked_or_muted_count DESC,
        v.record_data ASC
    LIMIT limit_count;
END;
$$;



--migrate:down