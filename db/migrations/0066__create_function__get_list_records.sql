-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_records
-- Description: Retrieves a list of records for a specified token_id from the
--              list_records table, ensuring the list storage location is valid.
-- Parameters:
--   - param_token_id (BIGINT): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'record_version' (types.uint8), 'record_type'
--          (types.uint8), and 'data' (BYTEA), representing the list record
--          version, type, and data.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_records (token_id BIGINT) RETURNS TABLE (
  record_version types.uint8,
  record_type types.uint8,
  record_data BYTEA
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT lr.record_version, lr.record_type, lr.record_data
  FROM public.efp_list_records AS lr
  JOIN query.get_list_storage_location(token_id) AS lsl
  ON lr.chain_id = lsl.chain_id
    AND lr.contract_address = lsl.contract_address
    AND lr.slot = lsl.slot;
END;
$$;



-- migrate:down