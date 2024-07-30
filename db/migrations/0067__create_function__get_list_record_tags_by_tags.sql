-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_record_tags_by_tags
-- Description: Retrieves a list of records for a specified token_id and array 
--              of tags from the list_records table, ensuring the list storage 
--              location is valid.
-- Parameters:
--   - param_token_id (BIGINT): The token_id for which to retrieve the list
--                              records.
--   - p_tags (text[]): The array of tags to match
-- Returns: A table with 'address' (types.eth_address), 'utags' (types.efp_tags),
--           representing the following address and its current tags
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_record_tags_by_tags (p_token_id BIGINT, p_tags types.efp_tag[]) RETURNS TABLE (
  address types.eth_address,
  utags types.efp_tag []
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        hexlify(record_data)::types.eth_address as address, 
        tags as utags
	FROM query.get_list_record_tags(p_token_id) v
	WHERE tags && p_tags;
END;
$$;



-- migrate:down