--migrate:up
-------------------------------------------------------------------------------
-- Function: get_following__record_type_001
-- Description: Retrieves a list of addresses followed by a user from the
--              view_list_records_with_nft_manager_user_tags, ensuring
--              addresses are valid 20-byte, lower-case hexadecimals (0x
--              followed by 40 hex chars). Filters tokens by version and type,
--              excluding blocked or muted relationships. Leverages primary
--              list token ID from get_primary_list. If no primary list is
--              found, returns an empty result set.
-- Parameters:
--   - address (types.eth_address): Identifier of the user to find the
--          following addresses.
-- Returns: A table with 'efp_list_nft_token_id' (BIGINT), 'record_version'
--          (types.uint8), 'record_type' (types.uint8), and 'following_address'
--          (types.eth_address), representing the list token ID, record
--          version, record type, and following address.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_following__record_type_001 (p_address types.eth_address) RETURNS TABLE (
  efp_list_nft_token_id BIGINT,
  record_version types.uint8,
  record_type types.uint8,
  following_address types.eth_address,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);

    -- Get the primary list token id
    SELECT v.primary_list_token_id
    INTO primary_list_token_id
    FROM public.view__efp_accounts_with_primary_list AS v
    WHERE v.address = normalized_addr;

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::types.uint8, NULL::types.uint8, NULL::types.eth_address, NULL::VARCHAR(255) [];
    END IF;

    -- else return the following addresses
    RETURN QUERY
    WITH primary_list AS (
        SELECT
            v.efp_list_nft_token_id,
            v.record_version,
            v.record_type,
            PUBLIC.hexlify(v.record_data)::types.eth_address AS following_address,
            v.tags
        FROM
            public.view__efp_list_records_with_nft_manager_user_tags AS v
        WHERE
            -- only version 1
            v.record_version = 1 AND
            -- address record type (1)
            v.record_type = 1 AND
            -- NOT blocked
            v.has_block_tag = FALSE AND
            -- NOT muted
            v.has_mute_tag = FALSE AND
            -- where the list user is the address we are looking for
            v.efp_list_user = normalized_addr AND
            -- from their primary list
            v.efp_list_nft_token_id = primary_list_token_id AND
            -- where the address record data field is a valid address
            public.is_valid_address(v.record_data)
    )
    SELECT * FROM primary_list
    ORDER BY
        efp_list_nft_token_id ASC,
        record_version ASC,
        record_type ASC,
        following_address ASC;
END;
$$;



--migrate:down