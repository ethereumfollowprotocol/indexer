--migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_records__record_type_001
-- Description: Retrieves all list records of a given type for a given user.
-- Parameters:
--   - p_address (VARCHAR(42)): Identifier of the user to find the list records
--                              of a given type for the user's primary list.
-- Returns: A table with 'efp_list_nft_token_id' (BIGINT), 'record_version'
--          (types.uint8), 'record_type' (types.uint8), and 'following_address'
--          (types.eth_address), representing the list token ID, record
--          version, record type, and following address.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_records__record_type_001 (p_address VARCHAR(42)) RETURNS TABLE (
  efp_list_nft_token_id BIGINT,
  record_version types.uint8,
  record_type types.uint8,
  address types.eth_address,
  tags types.efp_tag []
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
    SELECT v.primary_list_token_id
    INTO primary_list_token_id
    FROM public.view__events__efp_accounts_with_primary_list AS v
    WHERE v.address = normalized_addr;

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

    -- list records query
    RETURN QUERY
    SELECT
        (primary_list_token_id)::BIGINT AS efp_list_nft_token_id,
        v.record_version,
        v.record_type,
        PUBLIC.hexlify(v.record_data)::types.eth_address AS address,
        v.tags
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
        v.record_version ASC,
        v.record_type ASC,
        v.record_data ASC;
END;
$$;



--migrate:down