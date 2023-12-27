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
    FROM public.decode_efp_list_storage_location__v001__location_type_001(
        (SELECT nft.list_storage_location
         FROM public.list_nfts nft
         WHERE nft.token_id = input_token_id)
    ) AS dlsl
    WHERE dlsl.version = 1 AND dlsl.location_type = 1;
END;
$$;



-- migrate:down
