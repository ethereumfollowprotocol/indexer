-- migrate:up



-------------------------------------------------------------------------------
-- Function: get_primary_list
-- Description: Retrieves the primary list value for a given address from the
--              account_metadata table. If not found, falls back to finding the
--              lowest token_id from view_list_nfts_with_manager_user where
--              list_user equals the address. Converts valid hex string values
--              to BIGINT.
-- Parameters:
--   - addr (types.eth_address): The address for which to retrieve the
--          primary list value.
-- Returns: The BIGINT representation of the primary list value for the given
--          address, or the lowest token_id from with list_user equals the
--          address. Returns NULL if no primary list value is found.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_primary_list(
  address types.eth_address
)
RETURNS BIGINT
AS $$
DECLARE
    primary_list TEXT;
    normalized_addr types.eth_address;
    lowest_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_address(address);

    -- Retrieve the primary list value from account_metadata
    SELECT am.value INTO primary_list
    FROM account_metadata AS am
    WHERE am.address = normalized_addr AND am.key = 'efp.list.primary';

    -- Check if a primary list value was found and is valid
    IF primary_list IS NOT NULL THEN
        RETURN public.convert_hex_to_BIGINT(primary_list);
    END IF;

    -- Fallback: Retrieve the lowest token_id
    SELECT MIN(token_id) INTO lowest_token_id
    FROM view_list_nfts_with_manager_user
    WHERE list_user = normalized_addr;

    RETURN lowest_token_id;
END;
$$ LANGUAGE plpgsql;



-------------------------------------------------------------------------------
-- Function: get_following
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
-- Returns: A table with 'followed_address' (varchar(255)) and 'token_id'
--          (BIGINT), representing valid addresses being followed and the
--          relationship identifier. Returns empty table if no primary list is
--          found.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_following(address types.eth_address)
RETURNS TABLE(
  token_id BIGINT,
  version types.uint8,
  record_type types.uint8,
  data types.eth_address,
  tags VARCHAR(255)[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_address(address);

    -- Get the primary list token id once
    primary_list_token_id := public.get_primary_list(address);

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::varchar(255) WHERE FALSE;
    END IF;

    -- else return the following addresses
    RETURN QUERY
    WITH primary_list AS (
        SELECT
            v.token_id,
            v.version,
            v.record_type,
            v.data::types.eth_address,
            v.tags
        FROM
            view_list_records_with_nft_manager_user_tags AS v
        WHERE
            -- only version 1
            v.version = 1 AND
            -- address record type (1)
            v.record_type = 1 AND
            -- NOT blocked
            v.has_block_tag = FALSE AND
            -- NOT muted
            v.has_mute_tag = FALSE AND
            -- where the list user is the address we are looking for
            v.list_user = normalized_addr AND
            -- from their primary list
            v.token_id = primary_list_token_id AND
            -- where the address record data field is a valid address
            public.is_valid_address(v.data)
    )
    SELECT * FROM primary_list
    ORDER BY
        token_id ASC,
        version ASC,
        record_type ASC,
        data ASC;
END;
$$;



-------------------------------------------------------------------------------
-- Function: count_unique_following_by_address
-- Description: Counts the unique addresses that each user is following in the
--              view_list_records_with_nft_manager_user_tags, groups the
--              results by user, and orders them by the number of unique
--              addresses in descending order. Includes a LIMIT parameter to
--              control the number of returned rows. The function filters by
--              version and type, excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (text) and 'following_count' (BIGINT),
--          representing each user and their count of unique following
--          addresses.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.count_unique_following_by_address(
  limit_count BIGINT
)
RETURNS TABLE(
  address types.eth_address,
  following_count BIGINT
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    RETURN QUERY
  SELECT
        v.list_user AS address,
        COUNT(DISTINCT v.data) AS following_count
    FROM
        view_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only version 1
        v.version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE AND
        -- valid address format
        public.is_valid_address(v.data)
    GROUP BY
        v.list_user
    ORDER BY
        following_count DESC,
        v.list_user ASC
    LIMIT limit_count;
END;
$$;

-- migrate:down