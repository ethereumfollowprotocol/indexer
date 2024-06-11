--migrate:up
-------------------------------------------------------------------------------
-- Function: get_ens_metadata_by_address
-- Parameters:
--   - addr (VARCHAR(42)): The address for which to retrieve the ens data.
-- Returns: .
--          .
--          .
-------------------------------------------------------------------------------

CREATE
OR REPLACE FUNCTION query.get_ens_metadata_by_address (p_address types.eth_address) RETURNS TABLE (
    name TEXT,
    address types.eth_address,
    avatar TEXT,
	updated_at timestamp WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    normalized_addr := public.normalize_eth_address(p_address);
    RETURN QUERY
    SELECT DISTINCT
        metadata.name as name,
        metadata.address as address,
        metadata.avatar as avatar,
	metadata.updated_at
    FROM
        public.ens_metadata as metadata
    WHERE
        metadata.address = normalized_addr
    ORDER BY
        metadata.updated_at DESC;
END;
$$;



--migrate:down