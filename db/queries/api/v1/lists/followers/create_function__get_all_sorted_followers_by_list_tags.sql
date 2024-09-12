--migrate:up
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_all_sorted_followers_by_list_tags (p_list_id INT, p_tags types.efp_tag[], p_sort text) RETURNS TABLE (
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
BEGIN
	direction = LOWER(p_sort);

    IF cardinality(p_tags) > 0 THEN
		RETURN QUERY
	    SELECT * 
	    FROM query.get_all_unique_followers_by_list(p_list_id) v
	    WHERE v.tags && p_tags
	    ORDER BY  
			(CASE WHEN direction = 'asc' THEN v.updated_at END) asc NULLS LAST,
			(CASE WHEN direction = 'desc' THEN v.updated_at END) desc NULLS LAST;
	ELSE
        RETURN QUERY
	    SELECT * 
	    FROM query.get_all_unique_followers_by_list(p_list_id) v
	    ORDER BY  
			(CASE WHEN direction = 'asc' THEN v.updated_at END) asc NULLS LAST,
			(CASE WHEN direction = 'desc' THEN v.updated_at END) desc NULLS LAST;
	END IF;
END;
$$;




--migrate:down