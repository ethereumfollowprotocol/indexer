-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_following
-- Description: This fix improves following lookups and adds ranks to the results. 
--              
---------------

DROP FUNCTION 
    IF EXISTS query.get_leaderboard_following(bigint);

CREATE
OR REPLACE FUNCTION query.get_leaderboard_following (limit_count BIGINT) RETURNS TABLE (address types.eth_address, following_count BIGINT, following_rank BIGINT) LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY
    SELECT v.address AS address, 
        v.following AS following_count,
        v.following_rank AS following_rank
    FROM public.efp_leaderboard v
    WHERE v.following_rank > 0
    ORDER BY v.following DESC
    LIMIT limit_count;
END;
$$;

--migrate:down