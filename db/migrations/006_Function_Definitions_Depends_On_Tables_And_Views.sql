-- migrate:up

-- Function: get_followers
-- Description: Retrieves a list of followers based on the provided address.
-- Parameters:
--   - address (text): The address to filter the followers.
-- Returns:
--   - A table containing chain_id, contract_address, nonce, token_id, and list_user.

CREATE OR REPLACE FUNCTION public.get_followers(address text)
RETURNS TABLE(token_id bigint, list_user character varying(255))
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- the token id that follows the <address>
        lrtev.token_id,
        -- the list user of the EFP List that follows the <address>
        lrtev.list_user
        -- where the list is stored
        -- lrtev.list_storage_location_chain_id,
        -- lrtev.list_storage_location_contract_address,
        -- lrtev.list_storage_location_nonce
    FROM
        list_record_tags_extended_view AS lrtev
    WHERE
        -- only version 1
        lrtev.version = 1 AND
        -- only type 1 ("address record")
        lrtev.type = 1 AND
        -- NOT blocked
        lrtev.has_block_tag = FALSE AND
        -- NOT muted
        lrtev.has_mute_tag = FALSE AND
        -- who follow the address (the "data" of the address record is the address that is followed)
        lrtev.data = address
    ORDER BY
        lrtev.token_id ASC;
END;
$$;

-- migrate:down