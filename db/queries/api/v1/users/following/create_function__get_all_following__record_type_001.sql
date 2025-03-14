--migrate:up
-------------------------------------------------------------------------------
-- Function: get_following__record_type_001
-- Description: Retrieves a list of addresses followed by a user from the
--              view_list_records_with_nft_manager_user_tags, ensuring
--              addresses are valid 20-byte, lower-case hexadecimals (0x
--              followed by 40 hex chars). Filters tokens by version and type,
--              including blocked or muted relationships. Leverages primary
--              list token ID from get_primary_list. If no primary list is
--              found, returns an empty result set.
-- Parameters:
--   - address (VARCHAR(42)): Identifier of the user to find the
--                            following addresses.
-- Returns: A table with 'efp_list_nft_token_id' (BIGINT), 'record_version'
--          (types.uint8), 'record_type' (types.uint8), and 'following_address'
--          (types.eth_address), representing the list token ID, record
--          version, record type, and following address.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_all_following__record_type_001 (p_address VARCHAR(42)) RETURNS TABLE (
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
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);

    -- Get the primary list token id
	SELECT l.token_id 
    INTO primary_list_token_id
    FROM public.efp_lists l 
    JOIN public.efp_list_metadata m 
        ON m.chain_id = l.list_storage_location_chain_id
        AND m.contract_address = l.list_storage_location_contract_address
        AND m.slot = l.list_storage_location_slot,
    efp_account_metadata meta
    WHERE meta.address::text = m.value::text 
        AND meta.key = 'primary-list'
        AND convert_hex_to_bigint(meta.value::text) = l.token_id::bigint
        AND meta.address = normalized_addr
    GROUP BY l.token_id;

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NULL THEN
        RETURN; -- Exit the function without returning any rows
    END IF;

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
        COALESCE(v.tags, '{}') AS tags,
        v.updated_at
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
        public.is_valid_address(v.record_data)
    ORDER BY
        v.updated_at DESC,
        v.record_version ASC,
        v.record_type ASC,
        v.record_data ASC;
END;
$$;



--migrate:down