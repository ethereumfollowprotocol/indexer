-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_records
-- Description: Retrieves a list of records for a specified token_id from the
--              list_records table, ensuring the list storage location is valid.
-- Parameters:
--   - param_token_id (BIGINT): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'version' (SMALLINT), 'record_type' (SMALLINT), and
--          'data' (varchar(255)), representing the list record version, type,
--          and data.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_records (token_id BIGINT) RETURNS TABLE (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT lr.version, lr.record_type, lr.data
  FROM public.list_records AS lr
  JOIN query.get_list_storage_location(token_id) AS lsl
  ON lr.chain_id = lsl.chain_id
    AND lr.contract_address = lsl.contract_address
    AND lr.nonce = lsl.nonce;
END;
$$;



-------------------------------------------------------------------------------
-- Function: get_list_record_tags
-- Description: Retrieves a list of records for a specified token_id from the
--              list_records table, ensuring the list storage location is valid.
-- Parameters:
--   - param_token_id (BIGINT): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'version' (SMALLINT), 'record_type' (SMALLINT), and
--          'data' (varchar(255)), representing the list record version, type,
--          and data.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_record_tags (token_id BIGINT) RETURNS TABLE (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring,
  tags VARCHAR(255) []
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT
      record_tags.version,
      record_tags.record_type,
      record_tags.data,
      record_tags.tags
    FROM public.view_list_records_with_tag_array AS record_tags
    JOIN query.get_list_storage_location(token_id) AS list_storage_location
    ON record_tags.chain_id = list_storage_location.chain_id
      AND record_tags.contract_address = list_storage_location.contract_address
      AND record_tags.nonce = list_storage_location.nonce;
END;
$$;



-- migrate:down
