--migrate:up
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_sorted_followers_by_address_tags (p_address types.eth_address, p_tags types.efp_tag[], p_sort text) RETURNS TABLE (
  follower types.eth_address,
  efp_list_nft_token_id types.efp_list_nft_token_id,
  tags types.efp_tag [],
  is_following BOOLEAN,
  is_blocked BOOLEAN,
  is_muted BOOLEAN,
  updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    direction text;
    normalized_addr types.eth_address;
BEGIN
    direction = LOWER(p_sort);
    normalized_addr := public.normalize_eth_address(p_address);

    IF cardinality(p_tags) > 0 THEN
        RETURN QUERY
        SELECT 
            v.follower,
            v.efp_list_nft_token_id,
            v.tags,
            v.is_following,
            v.is_blocked,
            v.is_muted,
            v.updated_at 
        FROM query.get_unique_followers(normalized_addr) v
        LEFT JOIN public.efp_leaderboard l ON v.follower = l.address
        WHERE v.tags && p_tags
        ORDER BY  
            (CASE WHEN direction = 'followers' THEN l.followers END) DESC NULLS LAST,
            (CASE WHEN direction = 'earliest' THEN v.updated_at END) ASC NULLS LAST,
            (CASE WHEN direction = 'latest' THEN v.updated_at END) DESC NULLS LAST;
    ELSE
        RETURN QUERY
        SELECT 
            v.follower,
            v.efp_list_nft_token_id,
            v.tags,
            v.is_following,
            v.is_blocked,
            v.is_muted,
            v.updated_at 
        FROM query.get_unique_followers(normalized_addr) v
        LEFT JOIN public.efp_leaderboard l ON v.follower = l.address
        ORDER BY  
            (CASE WHEN direction = 'followers' THEN l.followers END) DESC NULLS LAST,
            (CASE WHEN direction = 'earliest' THEN v.updated_at END) ASC NULLS LAST,
            (CASE WHEN direction = 'latest' THEN v.updated_at END) DESC NULLS LAST;
    END IF;
END;
$$;




--migrate:down