--migrate:up
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_latest_followers_by_list (p_list_id INT,  p_limit BIGINT, p_offset BIGINT) RETURNS TABLE (
  follower types.eth_address,
  efp_list_nft_token_id types.efp_list_nft_token_id,
  updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    addr_bytea bytea;
BEGIN

    SELECT v.user 
    INTO normalized_addr
    FROM public.view__join__efp_lists_with_metadata as v 
    WHERE token_id = p_list_id;

	addr_bytea := public.unhexlify(normalized_addr);

    RETURN QUERY

    SELECT
        l.user AS follower,
        l.token_id AS efp_list_nft_token_id,
        r.updated_at
    FROM
        efp_list_records r
	    JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
	    JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
    WHERE
        -- only list record version 1
        r.record_version = 1 AND
        -- address record type (1)
        r.record_type = 1 AND
        -- match the address parameter
        r.record_data = addr_bytea AND
        -- Valid record data lookup
        l.user IS NOT NULL 
    GROUP BY
        l.user,
        l.token_id,
        r.record_data,
        r.updated_at 
    ORDER BY
        r.updated_at DESC
    LIMIT p_limit   
    OFFSET p_offset;
END;
$$;




--migrate:down