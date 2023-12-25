-- migrate:up

-------------------------------------------------------------------------------
-- Function: get_followers
-- Description: Retrieves a list of followers for a specified address from the
--              list_record_tags_extended_view. It filters tokens by version and
--              type, excluding blocked or muted relationships.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with 'token_id' (bigint) and 'list_user' (varchar(255)),
--          representing the relationship identifier and the follower's name.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_followers(address character varying(42))
RETURNS TABLE(token_id bigint, list_user character varying(42))
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
        -- the token id that follows the <address>
        lrtev.token_id,
        -- the list user of the EFP List that follows the <address>
        lrtev.list_user
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only list record version 1
        lrtev.version = 1 AND
        -- address record type (1)
        lrtev.record_type = 1 AND
        -- valid address format
        public.is_valid_address(lrtev.data) AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE AND
        -- who follow the address
        -- (the "data" of the address record is the address that is followed)
        lrtev.data = normalized_addr
    ORDER BY
        lrtev.token_id ASC;
END;
$$;


-------------------------------------------------------------------------------
-- Function: get_unique_followers
-- Description: Retrieves a distinct list of followers for a specified address,
--              de-duplicating by 'list_user'. This ensures each follower is
--              listed once, even if associated with multiple tokens.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
-- Returns: A table with 'list_user' (varchar(255)), representing unique names
--          or identifiers of the followers.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_unique_followers(address character varying(42))
RETURNS TABLE(list_user character varying(42))
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
    SELECT DISTINCT
        lrtev.list_user
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only list record version 1
        lrtev.version = 1 AND
        -- address record type (1)
        lrtev.record_type = 1 AND
        -- valid address format
        public.is_valid_address(lrtev.data) AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE AND
        -- match the address parameter
        lrtev.data = normalized_addr
    ORDER BY
        lrtev.list_user ASC;
END;
$$;



-------------------------------------------------------------------------------
-- Function: count_unique_followers_by_address
-- Description: Counts the unique followers for each address in the
--              list_record_tags_extended_view, groups the results by address,
--              and orders them by the number of unique followers in descending
--              order. Includes a LIMIT parameter to control the number of
--              returned rows. The function filters by version and type,
--              excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (bigint): The maximum number of rows to return.
-- Returns: A table with 'address' (text) and 'follower_count' (bigint),
--          representing each address and its count of unique followers.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.count_unique_followers_by_address(limit_count bigint)
RETURNS TABLE(address character varying(42), followers_count bigint)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        lrtev.data AS address,
        COUNT(DISTINCT lrtev.list_user) AS followers_count
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only list record version 1
        lrtev.version = 1 AND
        -- address record type (1)
        lrtev.record_type = 1 AND
        -- valid address format
        public.is_valid_address(lrtev.data) AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE
    GROUP BY
        lrtev.data
    ORDER BY
        followers_count DESC,
        lrtev.data ASC
    LIMIT limit_count;
END;
$$;

-- migrate:down