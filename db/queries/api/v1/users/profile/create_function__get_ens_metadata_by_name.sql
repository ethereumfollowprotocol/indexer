--migrate:up
-------------------------------------------------------------------------------
-- Function: get_ens_metadata_by_name
-- Parameters:
--   - addr (VARCHAR(42)): The address for which to retrieve the ens data.
-- Returns: .
--          .
--          .
-------------------------------------------------------------------------------

CREATE
OR REPLACE FUNCTION query.get_ens_metadata_by_name (p_name TEXT) RETURNS TABLE (
    name TEXT,
    address types.eth_address,
    avatar TEXT,
	updated_at timestamp WITH TIME ZONE
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        metadata.name as name,
        metadata.address as address,
        metadata.avatar as avatar,
	    metadata.updated_at
    FROM
        public.ens_metadata as metadata
    WHERE
        metadata.name = p_name
    ORDER BY
        metadata.updated_at DESC;
END;
$$;


--migrate:down