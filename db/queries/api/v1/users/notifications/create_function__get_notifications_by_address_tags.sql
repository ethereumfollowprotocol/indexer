--migrate:up
-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_notifications_by_address_tags (p_address types.eth_address, p_opcode BIGINT, p_interval INTERVAL, p_tag types.efp_tag, p_limit BIGINT, p_offset BIGINT) RETURNS TABLE (
    address types.eth_address,
    name TEXT,
    avatar TEXT,
    token_id types.efp_list_nft_token_id,
    opcode types.uint8,
    op types.hexstring,
    tag TEXT,
    updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
BEGIN
    normalized_addr := public.normalize_eth_address(p_address);
    RETURN QUERY

    SELECT
        l.user AS address,
        ens.name AS name,
        ens.avatar AS avatar,
        l.token_id AS token_id,
        r.opcode,
        r.op,
        convert_from(decode(substring(r.op, 51, 64), 'hex')::bytea, 'utf-8') as tag,
        r.updated_at
    FROM efp_list_ops r
        JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
        JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
        LEFT JOIN ens_metadata ens ON l.user = ens.address
    WHERE r.op ~ substring(normalized_addr, 3, 40) 
		AND (p_opcode = 0 OR r.opcode = p_opcode)
        AND (p_interval = '999:00:00' OR (now() - r.updated_at) <= p_interval)
        AND (p_tag = 'p_tag_empty' OR convert_from(decode(substring(r.op, 51, 64), 'hex')::bytea, 'utf-8') = p_tag)
    ORDER BY r.updated_at DESC
    LIMIT p_limit   
    OFFSET p_offset;
END;
$$;

--migrate:down