--migrate:up
-------------------------------------------------------------------------------
-- Function: get_following_page_by_list
-- Description: Retrieves a limited list of primary lists followed by a user from 
--              the view_list_records_with_nft_manager_user_tags. Filters tokens
--              by version and type, excluding blocked or muted relationships.
--              Leverages primary list token ID from get_primary_list. If no 
--              primary list is found, returns an empty result set.
-- Parameters:
--   - list_id (INT): Identifier of the user to find the following addresses.
--   - limit   (INT): Number of records to retrieve
--   - offset  (INT): Starting index to begin returned record set
-- Returns: A table with 'efp_list_nft_token_id' (BIGINT), 'record_version'
--          (types.uint8), 'record_type' (types.uint8), and 'following_address'
--          (types.eth_address), representing the list token ID, record
--          version, record type, and following address.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_following_page_by_list (p_list_id INT, p_limit INT, p_offset INT) RETURNS TABLE (
  efp_list_nft_token_id BIGINT,
  record_version types.uint8,
  record_type types.uint8,
  following_address types.eth_address,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
DECLARE
    primary_list_token_id BIGINT;
    list_storage_location_chain_id BIGINT;
    list_storage_location_contract_address VARCHAR(42);
    list_storage_location_storage_slot types.efp_list_storage_location_slot;
BEGIN
    primary_list_token_id = p_list_id;

    -- Now determine the list storage location for the primary list token id
    SELECT
      v.efp_list_storage_location_chain_id,
      v.efp_list_storage_location_contract_address,
      v.efp_list_storage_location_slot
    INTO
      list_storage_location_chain_id,
      list_storage_location_contract_address,
      list_storage_location_storage_slot
    FROM
      public.view__events__efp_list_storage_locations AS v
    WHERE
      v.efp_list_nft_token_id = primary_list_token_id;

    -- following query
    RETURN QUERY
    SELECT
        (primary_list_token_id)::BIGINT AS efp_list_nft_token_id,
        v.record_version,
        v.record_type,
        PUBLIC.hexlify(v.record_data)::types.eth_address AS following_address,
        COALESCE(v.tags, '{}') AS tags
    FROM
        public.view__join__efp_list_records_with_tags AS v
    WHERE
        v.chain_id = list_storage_location_chain_id AND
        v.contract_address = list_storage_location_contract_address AND
        v.slot = list_storage_location_storage_slot AND
        -- only version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- where the address record data field is a valid address
        public.is_valid_address(v.record_data) AND
        -- NOT blocked or muted
        NOT EXISTS (
            SELECT 1 FROM unnest(v.tags) as tag
            WHERE tag IN ('block', 'mute')
        )
    ORDER BY
        v.record_version ASC,
        v.record_type ASC,
        v.updated_at DESC,
        v.record_data ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;


--migrate:down