--migrate:up
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_recommended_by_list (p_list_id INT, p_limit BIGINT, p_offset BIGINT) RETURNS TABLE (
  name TEXT,
  address types.eth_address,
  avatar TEXT,
  header TEXT,
  class TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    SELECT v.user 
    INTO normalized_addr
    FROM public.view__join__efp_lists_with_metadata as v 
    WHERE token_id = p_list_id;

    RETURN QUERY

    SELECT 
        efp_recommended.name,
        efp_recommended.address,
        efp_recommended.avatar,
        efp_recommended.header,
        efp_recommended.class,
        efp_recommended.created_at
    FROM public.efp_recommended
    WHERE NOT EXISTS (
        SELECT 1 
        FROM query.get_all_following_by_list(p_list_id) fol
        WHERE efp_recommended.address = fol.following_address
    )
    AND efp_recommended.address <> normalized_addr
    ORDER BY efp_recommended.index
    LIMIT p_limit   
    OFFSET p_offset;
END;
$$;




--migrate:down