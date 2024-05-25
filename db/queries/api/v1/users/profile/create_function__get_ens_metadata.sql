--migrate:up
-------------------------------------------------------------------------------
-- Function: get_ens_metadata
-- Description: Retrieves the primary list value for a given address from the
--              account_metadata table. If not found, falls back to finding the
--              lowest token_id from view_list_nfts_with_manager_user where
--              list_user equals the address. Converts valid hex string values
--              to BIGINT.
-- Parameters:
--   - addr (VARCHAR(42)): The address for which to retrieve the ens data.
-- Returns: .
--          .
--          .
-------------------------------------------------------------------------------

CREATE
OR REPLACE FUNCTION query.get_ens_metadata (p_address types.eth_address) RETURNS TABLE (
    username TEXT,
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
        metadata.name as username,
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