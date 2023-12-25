-- migrate:up

-- Function: get_followers
-- Description: Retrieves a list of followers based on the provided address.
-- Parameters:
--   - address (text): The address to filter the followers.
-- Returns:
--   - A table containing chain_id, contract_address, nonce, token_id, and list_user.

CREATE OR REPLACE FUNCTION public.get_followers(address text)
RETURNS TABLE(chain_id bigint, contract_address character varying(42), nonce bigint, token_id bigint, list_user character varying(255))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Return query that fetches followers
    RETURN QUERY
    SELECT
        lr.chain_id,
        lr.contract_address,
        lr.nonce,
        nft.token_id,
        nft.list_user
    FROM
        list_records AS lr
    INNER JOIN
        list_nfts_view AS nft
    ON
        -- Joining conditions
        lr.chain_id = nft.list_storage_location_chain_id AND
        lr.contract_address = nft.list_storage_location_contract_address AND
        lr.nonce = nft.list_storage_location_nonce
    WHERE
        -- Filtering conditions
        lr.version = 1 AND
        lr.type = 1 AND
        lr.data = address
    ORDER BY
        nft.token_id ASC;
END;
$$;

-- migrate:down