-- migrate:up
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
  efp_list_nft_token_id types.efp_list_nft_token_id,
  efp_list_user types.eth_address,
  record_version types.uint8,
  record_type types.uint8,
  record_data types.hexstring,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(address);

    -- Get the primary list token id once
    SELECT v.primary_list_token_id
    INTO primary_list_token_id
    FROM public.view__events__efp_accounts_with_primary_list AS v
    WHERE v.address = normalized_addr;

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::varchar(255) WHERE FALSE;
    END IF;

    -- else return the matching outgoing relationships
    RETURN QUERY
    WITH primary_list AS (
        SELECT
            v.token_id AS efp_list_nft_token_id,
            v.user AS efp_list_user,
            v.record_version,
            v.record_type,
            v.record_data,
            v.tags
        FROM
            public.view__join__efp_list_records_with_nft_manager_user_tags AS v
        WHERE
            -- only list record version 1
            v.record_version = 1 AND
            -- address record type (1)
            v.record_type = 1 AND
            -- valid address format
            public.is_valid_address(v.record_data) AND
            -- who is followed by the list user
            v.user = normalized_addr AND
            -- from their primary list
            v.token_id = primary_list_token_id AND
            -- okay if blocked/muted we are looking at tags in general
            -- tag is in the list of tags
            v.tags @> ARRAY[tag]::varchar(255)[]
    )
    SELECT * FROM primary_list
    ORDER BY
        efp_list_nft_token_id ASC,
        record_version ASC,
        record_type ASC,
        record_data ASC;
END;
$$;



-- migrate:down