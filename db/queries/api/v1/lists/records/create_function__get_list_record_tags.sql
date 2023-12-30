-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_record_tags
-- Description: Retrieves a list of records for a specified token_id from the
--              list_records table, ensuring the list storage location is valid.
-- Parameters:
--   - param_token_id (BIGINT): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'version' (types.uint8), 'record_type' (types.uint8),
--          and 'record_data' (BYTEA), representing the list record version,
--          type, and data.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_record_tags (token_id BIGINT) RETURNS TABLE (
  record_version types.uint8,
  record_type types.uint8,
  record_data BYTEA,
  tags types.efp_tag []
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
      record_tags.record_version,
      record_tags.record_type,
      record_tags.record_data,
      record_tags.tags
    FROM public.view__efp_list_records_with_tags AS record_tags
    JOIN query.get_list_storage_location(token_id) AS list_storage_location
    ON record_tags.chain_id = list_storage_location.chain_id
      AND record_tags.contract_address = list_storage_location.contract_address
      AND record_tags.nonce = list_storage_location.nonce;
END;
$$;



-- migrate:down