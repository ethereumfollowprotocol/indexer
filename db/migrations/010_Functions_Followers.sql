-- migrate:up

-------------------------------------------------------------------------------
-- Function: get_followers
-- Description: Retrieves a list of followers for a specified address from the
--              view_list_records_with_nft_manager_user_tags. It filters tokens by version and
--              type, excluding blocked or muted relationships.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with 'token_id' (BIGINT) and 'list_user' (VARCHAR(255)),
--          representing the relationship identifier and the follower's name.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_followers(
  address types.eth_address
)
RETURNS TABLE(
  token_id BIGINT,
  list_user types.eth_address
)
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_address(address);

    RETURN QUERY
    SELECT
        -- the token id that follows the <address>
        v.token_id,
        -- the list user of the EFP List that follows the <address>
        v.list_user
    FROM
        view_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.data) AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE AND
        -- who follow the address
        -- (the "data" of the address record is the address that is followed)
        v.data = normalized_addr
    ORDER BY
        v.token_id ASC;
END;
$$;


-------------------------------------------------------------------------------
-- Function: get_unique_followers
-- Description: Retrieves a distinct list of followers for a specified address,
--              de-duplicating by 'list_user'. This ensures each follower is
--              listed once, even if associated with multiple tokens.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with 'list_user' (VARCHAR(255)), representing unique names
--          or identifiers of the followers.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_unique_followers(
  address types.eth_address
)
RETURNS TABLE(
  list_user types.eth_address
)
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_address(address);

    RETURN QUERY
    SELECT DISTINCT
        v.list_user
    FROM
        view_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.data) AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE AND
        -- match the address parameter
        v.data = normalized_addr
    ORDER BY
        v.list_user ASC;
END;
$$;



-------------------------------------------------------------------------------
-- Function: count_unique_followers_by_address
-- Description: Counts the unique followers for each address in the
--              view_list_records_with_nft_manager_user_tags, groups the results by address,
--              and orders them by the number of unique followers in descending
--              order. Includes a LIMIT parameter to control the number of
--              returned rows. The function filters by version and type,
--              excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (BIGINT): The maximum number of rows to return.
-- Returns: A table with 'address' (text) and 'follower_count' (BIGINT),
--          representing each address and its count of unique followers.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.count_unique_followers_by_address(
  limit_count BIGINT
)
RETURNS TABLE(
  address types.eth_address,
  followers_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.data::types.eth_address AS address,
        COUNT(DISTINCT v.list_user) AS followers_count
    FROM
        view_list_records_with_nft_manager_user_tags AS v
    WHERE
        -- only list record version 1
        v.version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.data) AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE
    GROUP BY
        v.data
    ORDER BY
        followers_count DESC,
        v.data ASC
    LIMIT limit_count;
END;
$$;

-- migrate:down