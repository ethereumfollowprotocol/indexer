-- migrate:up



-------------------------------------------------------------------------------
-- Function: get_primary_list
-- Description: Retrieves the primary list value for a given address from the
--              account_metadata table and converts it to a bigint. Utilizes
--              convert_hex_to_bigint to perform the conversion. The function
--              expects the primary list value to be a valid 66-character
--              hexadecimal string.
-- Parameters:
--   - addr (character varying(42)): The address for which to retrieve the
--          primary list value.
-- Returns: The bigint representation of the primary list value for the given
--          address, or NULL if the value is invalid or not found.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_primary_list(addr character varying(42))
RETURNS bigint AS $$
DECLARE
    primary_list text;
BEGIN
    -- Retrieve the primary list value from account_metadata
    SELECT am.value INTO primary_list
    FROM account_metadata AS am
    WHERE am.address = addr AND am.key = 'efp.list.primary';

    -- Return the decoded primary list
    RETURN public.convert_hex_to_bigint(primary_list);
END;
$$ LANGUAGE plpgsql;


-------------------------------------------------------------------------------
-- Function: get_following
-- Description: Retrieves a list of addresses that a specified user is following
--              from the list_record_tags_extended_view, ensuring the addresses
--              are valid 20-byte, lower-case hexadecimal (0x followed by 40
--              hexadecimal characters). Filters tokens by version and type,
--              excluding blocked or muted relationships.
-- Parameters:
--   - user_id (text): Identifier of the user to find the following addresses.
-- Returns: A table with 'followed_address' (varchar(255)) and 'token_id' (bigint),
--          representing valid addresses being followed and the relationship
--          identifier.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_following(address character varying(42))
RETURNS TABLE(token_id bigint, followed_address character varying(255))
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- the token id that corresponds to the following action
        lrtev.token_id,
        -- the address being followed
        lrtev.data AS followed_address
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only version 1
        lrtev.version = 1 AND
        -- address record type (1)
        lrtev.record_type = 1 AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE AND
        -- user who is following
        lrtev.list_user = address AND
        -- valid address format
        lrtev.data ~ '^0x[a-f0-9]{40}$'
    ORDER BY
        lrtev.token_id ASC,
        lrtev.data ASC;
END;
$$;



-------------------------------------------------------------------------------
-- Function: count_unique_following_by_address
-- Description: Counts the unique addresses that each user is following in the
--              list_record_tags_extended_view, groups the results by user, and
--              orders them by the number of unique addresses in descending
--              order. Includes a LIMIT parameter to control the number of
--              returned rows. The function filters by version and type,
--              excluding blocked or muted relationships.
-- Parameters:
--   - limit_count (bigint): The maximum number of rows to return.
-- Returns: tbd
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.count_unique_following_by_address(limit_count bigint)
RETURNS TABLE(address character varying(255), following_count bigint)
LANGUAGE PLPGSQL
AS $$
BEGIN
    RETURN QUERY
  SELECT
        lrtev.list_user AS address,
        COUNT(DISTINCT lrtev.data) AS following_count
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only version 1
        lrtev.version = 1 AND
        -- address record type (1)
        lrtev.record_type = 1 AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE AND
        -- valid address format
        lrtev.data ~ '^0x[a-f0-9]{40}$'
    GROUP BY
        lrtev.list_user
    ORDER BY
        following_count DESC,
        lrtev.list_user ASC
    LIMIT limit_count;
END;
$$;

-- migrate:down