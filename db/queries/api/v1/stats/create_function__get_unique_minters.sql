--migrate:up
-------------------------------------------------------------------------------
-- Function: get_unique_minters
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_unique_minters (p_limit INT, p_offset INT) RETURNS TABLE (
  address types.eth_address,
  name text,
  avatar text,
  list BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l."user" as address,
        meta.name,
        meta.avatar,
        MAX(l.token_id) as list
    FROM public.view__join__efp_lists_with_metadata l
    LEFT JOIN public.ens_metadata meta ON l."user" = meta.address 
    GROUP BY "user", meta.name, meta.avatar
    ORDER BY list DESC 
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;




--migrate:down