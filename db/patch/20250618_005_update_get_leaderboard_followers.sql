-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_followers
-- Description: This fix improves followers lookups and adds ranks to the results. 
--              
---------------

DROP FUNCTION 
    IF EXISTS query.get_leaderboard_followers(bigint);

CREATE
OR REPLACE FUNCTION query.get_leaderboard_followers (limit_count BIGINT) RETURNS TABLE (address types.eth_address, followers_count BIGINT, followers_rank BIGINT) LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY
    SELECT v.address AS address, 
        v.followers AS followers_count,
        v.followers_rank AS followers_rank
    FROM public.efp_leaderboard v
    WHERE v.followers_rank > 0
    ORDER BY v.followers DESC
    LIMIT limit_count;
END;
$$;

--migrate:down