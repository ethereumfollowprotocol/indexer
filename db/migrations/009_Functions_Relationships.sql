-- migrate:up



-------------------------------------------------------------------------------
-- Function: get_incoming_relationships
-- Description: Retrieves incoming relationships for a given address and a
--              specific tag from the list_record_tags_extended_view. It filters
--              records by a normalized version of the address and the specified
--              tag, identifying relationships where the address is referenced
--              in the data field of list records and the tag is in the tags
--              array.
-- Parameters:
--   - address (character varying(42)): The Ethereum address for which to
--                                      retrieve incoming relationships.
--   - tag (character varying(255)): The tag used to filter the relationships.
-- Returns: A table with 'token_id' (bigint), 'list_user' (character varying(42)),
--          and 'tags' (character varying(255)[]), representing the token
--          identifier, the user associated with the list, and the array of tags
--          associated with each relationship.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_incoming_relationships(
    address character varying(42),
    tag character varying(255)
)
RETURNS TABLE(
    token_id bigint,
    list_user character varying(42),
    tags character varying(255)[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_addr character varying(42);
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := LOWER(address);

    -- Validate the input address format
    IF NOT (public.is_valid_address(normalized_addr)) THEN
        RAISE EXCEPTION 'Invalid address format';
    END IF;

    RETURN QUERY
    SELECT
      lrtev.token_id,
      lrtev.list_user,
      lrtev.tags
    FROM list_record_tags_extended_view AS lrtev
    WHERE
      -- only list record version 1
      lrtev.version = 1 AND
      -- address record type (1)
      lrtev.record_type = 1 AND
      -- valid address format
      lrtev.data = normalized_addr AND
      -- ok if block/muted we are looking at tags in general
      -- tag is in the list of tags
      lrtev.tags @> ARRAY[tag]::varchar(255)[];
END;
$$;



-------------------------------------------------------------------------------
-- Function: get_outgoing_relationships
-- Description: Retrieves outgoing relationships from a specified user with a
--              particular tag from the list_record_tags_extended_view. This
--              function identifies relationships initiated by the given user
--              and filters them based on the specified tag. It's designed to
--              target records where the initiating user is linked in the
--              list records' 'list_user' field and the tag is present in the
--              tags array.
-- Parameters:
--   - list_user (character varying(42)): The user identifier for which to
--                                        retrieve outgoing relationships.
--   - tag (character varying(255)): The tag used to filter the relationships.
-- Returns: A table with 'token_id' (bigint), 'version' (smallint),
--          'record_type' (smallint), 'data' (character varying(255)), and
--          'tags' (character varying(255)[]), representing the token
--          identifier, the list record version, type, data, and tags.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_outgoing_relationships(
    address character varying(42),
    tag character varying(255)
)
RETURNS TABLE(
    token_id bigint,
    list_user character varying(42),
    version smallint,
    record_type smallint,
    data character varying(255),
    tags character varying(255)[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_addr character varying(42);
    primary_list_token_id bigint;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := LOWER(address);

    -- Validate the input address format
    IF NOT (public.is_valid_address(normalized_addr)) THEN
        RAISE EXCEPTION 'Invalid address format';
    END IF;

    -- Get the primary list token id once
    primary_list_token_id := public.get_primary_list(normalized_addr);

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN QUERY SELECT NULL::bigint, NULL::varchar(255) WHERE FALSE;
    END IF;

    -- else return the matching outgoing relationships
    RETURN QUERY
    WITH primary_list AS (
        SELECT
            lrtev.token_id,
            lrtev.list_user,
            lrtev.version,
            lrtev.record_type,
            lrtev.data,
            lrtev.tags
        FROM
            list_record_tags_extended_view AS lrtev
        WHERE
            -- only list record version 1
            lrtev.version = 1 AND
            -- address record type (1)
            lrtev.record_type = 1 AND
            -- valid address format
            public.is_valid_address(lrtev.data) AND
            -- who is followed by the list user
            lrtev.list_user = normalized_addr AND
            -- from their primary list
            lrtev.token_id = primary_list_token_id AND
            -- okay if blocked/muted we are looking at tags in general
            -- tag is in the list of tags
            lrtev.tags @> ARRAY[tag]::varchar(255)[]
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
