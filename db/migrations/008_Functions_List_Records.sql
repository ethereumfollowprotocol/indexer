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
         FROM list_nfts AS nfts
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
--   - param_token_id (bigint): The token_id for which to retrieve the list records.
-- Returns: A table with 'version' (smallint), 'record_type' (smallint), and
--          'data' (varchar(255)), representing the list record version, type,
--          and data.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_list_records(token_id bigint)
RETURNS TABLE(version smallint, record_type smallint, data character varying)
LANGUAGE plpgsql
AS $$
DECLARE
    list_storage_location_chain_id bigint;
    list_storage_location_contract_address character varying(42);
    list_storage_location_nonce bigint;
BEGIN

    SELECT
      lsl.chain_id,
      lsl.contract_address,
      lsl.nonce
    INTO
      list_storage_location_chain_id,
      list_storage_location_contract_address,
      list_storage_location_nonce
    FROM public.get_list_storage_location(token_id) AS lsl;

    -- Check if any of the decoded values is NULL (indicating list storage location was not found)
    IF list_storage_location_chain_id IS NULL THEN
        RETURN;
    END IF;

    -- Use the decoded values to filter the list_records
    RETURN QUERY
    SELECT lr.version, lr.record_type, lr.data
    FROM list_records AS lr
    WHERE lr.chain_id = list_storage_location_chain_id
      AND lr.contract_address = list_storage_location_contract_address
      AND lr.nonce = list_storage_location_nonce;
END;
$$;


SELECT * FROM public.get_list_records(0);

-- migrate:down