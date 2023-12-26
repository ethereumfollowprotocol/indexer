-- migrate:up



-------------------------------------------------------------------------------
-- Function: get_list_storage_location
-- Description: Retrieves the list storage location for a specified token_id
--              from the list_nfts table.
-- Parameters:
--   - input_token_id (bigint): The token_id for which to retrieve the list
--                              storage location.
-- Returns: A table with chain_id (bigint), contract_address (varchar(42)), and
--          nonce (bigint), representing the list storage location chain ID,
--          contract address, and nonce.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_list_storage_location(input_token_id bigint)
RETURNS TABLE(chain_id bigint, contract_address character varying(42), nonce bigint)
LANGUAGE plpgsql
AS $$
DECLARE
    list_storage_location character varying;
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
--   - param_token_id (bigint): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'version' (smallint), 'record_type' (smallint), and
--          'data' (varchar(255)), representing the list record version, type,
--          and data.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_list_records(token_id bigint)
RETURNS TABLE(version smallint, record_type smallint, data character varying(255))
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT lr.version, lr.record_type, lr.data
  FROM list_records AS lr
  JOIN public.get_list_storage_location(token_id) AS lsl
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
--   - param_token_id (bigint): The token_id for which to retrieve the list
--                              records.
-- Returns: A table with 'version' (smallint), 'record_type' (smallint), and
--          'data' (varchar(255)), representing the list record version, type,
--          and data.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_list_record_tags(token_id bigint)
RETURNS TABLE(version smallint, record_type smallint, data character varying(255), tags character varying(255)[])
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
      lrtv.version,
      lrtv.record_type,
      lrtv.data,
      lrtv.tags
    FROM list_record_tags_view AS lrtv
    JOIN public.get_list_storage_location(token_id) AS lsl
    ON lrtv.chain_id = lsl.chain_id
      AND lrtv.contract_address = lsl.contract_address
      AND lrtv.nonce = lsl.nonce;
END;
$$;

-- migrate:down
