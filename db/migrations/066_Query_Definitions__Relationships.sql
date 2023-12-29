-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_incoming_relationships
-- Description: Retrieves incoming relationships for a given address and a
--              specific tag from view_list_records_with_nft_manager_user_tags.
--              It filters records by a normalized version of the address and
--              the specified tag, identifying relationships where the address
--              is referenced in the data field of list records and the tag is
--              in the tags array.
-- Parameters:
--   - address (types.eth_address): The Ethereum address for which to
--                                      retrieve incoming relationships.
--   - tag (VARCHAR(255)): The tag used to filter the relationships.
-- Returns: A table with 'token_id' (BIGINT), 'list_user' (types.eth_address),
--          and 'tags' (VARCHAR(255)[]), representing the token
--          identifier, the user associated with the list, and the array of
--          tags associated with each relationship.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_incoming_relationships (address types.eth_address, tag VARCHAR(255)) RETURNS TABLE (
  token_id BIGINT,
  list_user types.eth_address,
  tags VARCHAR(255) []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(address);

    RETURN QUERY
    SELECT
      v.token_id,
      v.list_user,
      v.tags
    FROM public.view_list_records_with_nft_manager_user_tags AS v
    WHERE
      -- only list record version 1
      v.version = 1 AND
      -- address record type (1)
      v.record_type = 1 AND
      -- valid address format
      v.data = normalized_addr AND
      -- ok if block/muted we are looking at tags in general
      -- tag is in the list of tags
      v.tags @> ARRAY[tag]::varchar(255)[];
END;
$$;

-------------------------------------------------------------------------------
-- Function: get_outgoing_relationships
-- Description: Retrieves outgoing relationships from a specified user with a
--              particular tag from the view_list_records_with_nft_manager_user_tags. This
--              function identifies relationships initiated by the given user
--              and filters them based on the specified tag. It's designed to
--              target records where the initiating user is linked in the
--              list records' 'list_user' field and the tag is present in the
--              tags array.
-- Parameters:
--   - list_user (types.eth_address): The user identifier for which to
--                                        retrieve outgoing relationships.
--   - tag (VARCHAR(255)): The tag used to filter the relationships.
-- Returns: A table with 'token_id' (BIGINT), 'version' (SMALLINT),
--          'record_type' (SMALLINT), 'data' (types.hexstring), and
--          'tags' (VARCHAR(255)[]), representing the token
--          identifier, the list record version, type, data, and tags.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_outgoing_relationships (address types.eth_address, tag VARCHAR(255)) RETURNS TABLE (
  token_id BIGINT,
  list_user types.eth_address,
  version types.uint8,
  record_type types.uint8,
  data types.hexstring,
  tags VARCHAR(255) []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_address(address);

    -- Get the primary list token id once
    primary_list_token_id := query.get_primary_list(normalized_addr);

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::varchar(255) WHERE FALSE;
    END IF;

    -- else return the matching outgoing relationships
    RETURN QUERY
    WITH primary_list AS (
        SELECT
            v.token_id,
            v.list_user,
            v.version,
            v.record_type,
            v.data,
            v.tags
        FROM
            public.view_list_records_with_nft_manager_user_tags AS v
        WHERE
            -- only list record version 1
            v.version = 1 AND
            -- address record type (1)
            v.record_type = 1 AND
            -- valid address format
            public.is_valid_address(v.data) AND
            -- who is followed by the list user
            v.list_user = normalized_addr AND
            -- from their primary list
            v.token_id = primary_list_token_id AND
            -- okay if blocked/muted we are looking at tags in general
            -- tag is in the list of tags
            v.tags @> ARRAY[tag]::varchar(255)[]
    )
    SELECT * FROM primary_list
    ORDER BY
        token_id ASC,
        version ASC,
        record_type ASC,
        data ASC;
END;
$$;

-- migrate:down
