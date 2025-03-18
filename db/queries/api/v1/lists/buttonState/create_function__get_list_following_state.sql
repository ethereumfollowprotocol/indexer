--migrate:up
-------------------------------------------------------------------------------
-- Function: get_list_following_state
-- Description: Retrieves the state of relationship between a list holder and  
--              address, whether the list is following, blocking or muting,
--              the address.
-- Parameters:
--   - list_id (INT): The primary list id used to identify and filter followers.
-- Returns: A table with
--            'follower' (types.eth_address),
--            'efp_list_nft_token_id' (types.efp_list_nft_token_id),
--             tags (types.efp_tag []),
--            'is_following' (BOOLEAN),
--            'is_blocked' (BOOLEAN),
--            'is_muted' (BOOLEAN),
--          representing the list token ID, list user, and tags.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_list_following_state (p_token_id INT, p_address types.eth_address) RETURNS TABLE (
    is_following BOOLEAN,
	is_blocked BOOLEAN,
	is_muted BOOLEAN
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    primary_list_token_id BIGINT;
    lsl_chain_id BIGINT;
    lsl_contract_address VARCHAR(42);
    lsl_storage_slot types.efp_list_storage_location_slot;
BEGIN
	  normalized_addr := public.normalize_eth_address(p_address);
	-- Now determine the list storage location for the primary list token id
    
    SELECT
        v.list_storage_location_chain_id,
        v.list_storage_location_contract_address,
        v.list_storage_location_slot
    INTO
        lsl_chain_id,
        lsl_contract_address,
        lsl_storage_slot
    FROM
        public.view__join__efp_lists_with_metadata AS v
    WHERE
        v.token_id = p_token_id;
    RETURN QUERY

    SELECT 
        CASE
            WHEN 'block'::text = t.tag OR 'mute'::text = t.tag THEN false
            ELSE true
        END AS is_following,
        CASE
            WHEN 'block'::text = t.tag THEN true
            ELSE false
        END AS is_blocked,
        CASE
            WHEN 'mute'::text = t.tag THEN true
            ELSE false
        END AS is_muted
    FROM efp_list_records r
    LEFT JOIN efp_list_record_tags t ON r.chain_id::bigint = t.chain_id::bigint AND r.contract_address::text = t.contract_address::text AND r.slot::bytea = t.slot::bytea AND r.record = t.record
    JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
    -- JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
    WHERE 
        l.list_storage_location_slot = r.slot AND
        l.list_storage_location_contract_address = r.contract_address AND
        l.list_storage_location_chain_id = r.chain_id AND
        hexlify(r.record_data) = normalized_addr AND
        l.token_id = p_token_id
    GROUP BY is_following, is_blocked, is_muted;
END;
$$;


--migrate:down