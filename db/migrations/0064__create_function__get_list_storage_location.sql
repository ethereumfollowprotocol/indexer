-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_storage_location
-- Description: Retrieves the list storage location for a specified token_id.
-- Parameters:
--   - p_token_id (BIGINT): The token_id for which to retrieve the list
--                          storage location.
-- Returns: A table with chain_id (BIGINT), contract_address (varchar(42)), and
--          slot (BIGINT), representing the list storage location chain ID,
--          contract address, and slot.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_storage_location (p_token_id BIGINT) RETURNS TABLE (
  chain_id BIGINT,
  contract_address types.eth_address,
  slot types.efp_list_storage_location_slot
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    efp_list_storage_location_chain_id,
    efp_list_storage_location_contract_address,
    efp_list_storage_location_slot
  FROM
    public.view__events__efp_list_storage_locations
  WHERE
    efp_list_nft_token_id = p_token_id;
END;
$$;



-- migrate:down