-- migrate:up



-------------------------------------------------------------------------------
-- Function: get_list_storage_location
-- Description: Retrieves the list storage location for a specified token_id
--              from the list_nfts table.
-- Parameters:
--   - input_token_id (BIGINT): The token_id for which to retrieve the list
--                              storage location.
-- Returns: A table with chain_id (BIGINT), contract_address (varchar(42)), and
--          nonce (BIGINT), representing the list storage location chain ID,
--          contract address, and nonce.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION query.get_list_storage_location(
  input_token_id BIGINT
)
RETURNS TABLE(
  chain_id BIGINT,
  contract_address types.eth_address,
  nonce BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    list_storage_location VARCHAR;
BEGIN
    RETURN QUERY
    SELECT
      dlsl.chain_id,
      dlsl.contract_address,
      dlsl.nonce
    FROM public.decode_list_storage_location(
        (SELECT nfts.list_storage_location
         FROM public.list_nfts AS nfts
         WHERE nfts.token_id = input_token_id)
    ) AS dlsl
    WHERE dlsl.version = 1 AND dlsl.location_type = 1;
END;
$$;



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
CREATE OR REPLACE FUNCTION query.get_list_records(
  token_id BIGINT
)
RETURNS TABLE(
  version types.uint8,
  record_type types.uint8,
  data types.hexstring
)
LANGUAGE plpgsql
AS $$
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
CREATE OR REPLACE FUNCTION query.get_list_record_tags(
  token_id BIGINT
)
RETURNS TABLE(
  version types.uint8,
  record_type types.uint8,
  data types.hexstring,
  tags VARCHAR(255)[]
)
LANGUAGE plpgsql
AS $$
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
