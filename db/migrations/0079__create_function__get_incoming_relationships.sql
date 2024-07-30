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
  efp_list_nft_token_id types.efp_list_nft_token_id,
  efp_list_user types.eth_address,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(address);

    RETURN QUERY
    SELECT
      v.token_id AS efp_list_nft_token_id,
      v.user AS efp_list_user,
      v.tags
    FROM public.view__list_records_with_nft_manager_user_tags AS v
    WHERE
      -- only list record version 1
      v.record_version = 1 AND
      -- address record type (1)
      v.record_type = 1 AND
      -- valid address format
      v.record_data = PUBLIC.unhexlify(normalized_addr) AND
      -- ok if block/muted we are looking at tags in general
      -- tag is in the list of tags
      v.tags @> ARRAY[tag]::varchar(255)[];
END;
$$;



-- migrate:down