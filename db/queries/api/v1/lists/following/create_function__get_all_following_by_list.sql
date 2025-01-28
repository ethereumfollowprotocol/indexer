--migrate:up
-------------------------------------------------------------------------------
-- Function: get_following_by_list
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
OR REPLACE FUNCTION query.get_all_following_by_list (p_list_id INT) RETURNS TABLE (
  efp_list_nft_token_id BIGINT,
  record_version types.uint8,
  record_type types.uint8,
  following_address types.eth_address,
  tags types.efp_tag [],
  updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
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
        r.record_version,
        r.record_type,
        PUBLIC.hexlify(r.record_data)::types.eth_address AS following_address,
        array_agg(t.tag) FILTER (WHERE t.tag IS NOT NULL) AS tags,
        r.updated_at
    FROM efp_list_records r
    LEFT JOIN efp_list_record_tags t ON r.chain_id::bigint = t.chain_id::bigint AND r.contract_address::text = t.contract_address::text AND r.slot::bytea = t.slot::bytea AND r.record = t.record
    JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
    JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
    
    WHERE
        p_list_storage_location_chain_id = l.list_storage_location_chain_id AND
        p_list_storage_location_contract_address = l.list_storage_location_contract_address AND
        p_list_storage_location_storage_slot = l.list_storage_location_slot AND
        -- only version 1
        r.record_version = 1 AND
        -- address record type (1)
        r.record_type = 1 AND
        -- where the address record data field is a valid address
        public.is_valid_address(r.record_data)

    GROUP BY
        r.record_version,
        r.record_type,
        r.record_data,
        r.updated_at 
    ORDER BY
        r.record_version ASC,
        r.record_type ASC,
        r.updated_at DESC,
        r.record_data ASC
        ;
END;
$$;


--migrate:down