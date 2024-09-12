--migrate:up
-------------------------------------------------------------------------------
-- Function: get_get_leaderboard_ranked
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_leaderboard_ranked (p_limit INT, p_offset INT, p_column text, p_sort text) RETURNS TABLE (
  address types.eth_address,
  name text,
  avatar text,
  mutuals_rank BIGINT,
  followers_rank BIGINT,
  following_rank BIGINT,
  blocks_rank BIGINT,
  top8_rank BIGINT,
  mutuals BIGINT,
  following BIGINT,
  followers BIGINT,
  blocks BIGINT,
  top8 BIGINT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
	direction text;
    col text;
BEGIN
    direction = LOWER(p_sort);
    col = LOWER(p_column);

    IF col = 'following' THEN
        RETURN QUERY
        SELECT * 
        FROM public.efp_leaderboard v
        WHERE v.following_rank > 0
        ORDER BY  
            (CASE WHEN direction = 'asc' THEN v.following END) asc,
            (CASE WHEN direction = 'desc' THEN v.following END) desc
        LIMIT p_limit
        OFFSET p_offset;
    ELSEIF col = 'followers' THEN
        RETURN QUERY
        SELECT * 
        FROM public.efp_leaderboard v
        WHERE v.followers_rank > 0
        ORDER BY  
            (CASE WHEN direction = 'asc' THEN v.followers END) asc,
            (CASE WHEN direction = 'desc' THEN v.followers END) desc
        LIMIT p_limit
        OFFSET p_offset;
    ELSEIF col = 'blocked' THEN
        RETURN QUERY
        SELECT * 
        FROM public.efp_leaderboard v
        WHERE v.blocks_rank > 0
        ORDER BY  
            (CASE WHEN direction = 'asc' THEN v.blocks END) asc,
            (CASE WHEN direction = 'desc' THEN v.blocks END) desc
        LIMIT p_limit
        OFFSET p_offset;
    ELSEIF col = 'top8' THEN
        RETURN QUERY
        SELECT * 
        FROM public.efp_leaderboard v
        WHERE v.top8_rank > 0
        ORDER BY  
            (CASE WHEN direction = 'asc' THEN v.top8 END) asc,
            (CASE WHEN direction = 'desc' THEN v.top8 END) desc
        LIMIT p_limit
        OFFSET p_offset;
    ELSE
        RETURN QUERY
        SELECT * 
        FROM public.efp_leaderboard v
        WHERE v.mutuals_rank > 0
        ORDER BY  
            (CASE WHEN direction = 'asc' THEN v.mutuals END) asc,
            (CASE WHEN direction = 'desc' THEN v.mutuals END) desc
        LIMIT p_limit
        OFFSET p_offset;
    END IF;
END;
$$;




--migrate:down