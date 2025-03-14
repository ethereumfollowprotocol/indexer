--migrate:up
-------------------------------------------------------------------------------
-- Function: get_common_followers_by_address
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_common_followers_by_address(p_user_address types.eth_address, p_target_address types.eth_address) RETURNS TABLE (
    address types.eth_address,
    name TEXT,
    avatar TEXT,
    mutuals_rank BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_u_addr types.eth_address;
    normalized_t_addr types.eth_address;
    addr_t_bytea bytea;
    u_primary_list_token_id BIGINT;
    u_list_storage_location_chain_id BIGINT;
    u_list_storage_location_contract_address VARCHAR(42);
    u_list_storage_location_storage_slot types.efp_list_storage_location_slot;
BEGIN
	-- Normalize the input address to lowercase
    normalized_u_addr := public.normalize_eth_address(p_user_address);
    normalized_t_addr := public.normalize_eth_address(p_target_address);

    -- SELECT v.primary_list_token_id
    -- INTO u_primary_list_token_id
    -- FROM public.view__events__efp_accounts_with_primary_list AS v
    -- WHERE v.address = normalized_u_addr;

    SELECT l.token_id 
    INTO u_primary_list_token_id
    FROM public.efp_lists l 
    JOIN public.efp_list_metadata m 
        ON m.chain_id = l.list_storage_location_chain_id
        AND m.contract_address = l.list_storage_location_contract_address
        AND m.slot = l.list_storage_location_slot,
    efp_account_metadata meta
    WHERE meta.address::text = m.value::text 
        AND meta.key = 'primary-list'
        AND convert_hex_to_bigint(meta.value::text) = l.token_id::bigint
        AND meta.address = normalized_u_addr
    GROUP BY l.token_id;

    IF u_primary_list_token_id IS NOT NULL THEN

      -- Now determine the list storage location for the primary list token id
      SELECT
        v.efp_list_storage_location_chain_id,
        v.efp_list_storage_location_contract_address,
        v.efp_list_storage_location_slot
      INTO
        u_list_storage_location_chain_id,
        u_list_storage_location_contract_address,
        u_list_storage_location_storage_slot
      FROM
        public.view__events__efp_list_storage_locations AS v
      WHERE
        v.efp_list_nft_token_id = u_primary_list_token_id;
    END IF;

    addr_t_bytea := public.unhexlify(normalized_t_addr);


    CREATE TEMPORARY TABLE temp_list_records (
        nft_chain_id bigint,
        nft_contract_address varchar(42),
        token_id bigint,
        owner varchar(42),
        manager varchar(42),
        "user" varchar(42),
        list_storage_location_chain_id bigint,
        list_storage_location_contract_address varchar(42),
        list_storage_location_slot bytea,
        record bytea,
        record_version smallint,
        record_type smallint,
        record_data bytea,
        tags types.efp_tag[],
        updated_at timestamp with TIME ZONE,
        has_block_tag boolean,
        has_mute_tag boolean
    ) ON COMMIT DROP;

    INSERT INTO temp_list_records SELECT l.nft_chain_id,
        l.nft_contract_address,
        l.token_id,
        l.owner,
        l.manager,
        l."user",
        l.list_storage_location_chain_id,
        l.list_storage_location_contract_address,
        l.list_storage_location_slot,
        record_tags.record,
        record_tags.record_version,
        record_tags.record_type,
        record_tags.record_data,
        record_tags.tags,
        record_tags.updated_at,
            CASE
                WHEN 'block'::text = ANY (record_tags.tags::text[]) THEN true
                ELSE false
            END AS has_block_tag,
            CASE
                WHEN 'mute'::text = ANY (record_tags.tags::text[]) THEN true
                ELSE false
            END AS has_mute_tag
    FROM view__join__efp_list_records_with_tags record_tags
        LEFT JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = record_tags.chain_id::bigint AND l.list_storage_location_contract_address::text = record_tags.contract_address::text AND l.list_storage_location_slot::bytea = record_tags.slot::bytea
        JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
        WHERE 
        l.list_storage_location_chain_id = u_list_storage_location_chain_id AND
        l.list_storage_location_contract_address = u_list_storage_location_contract_address AND
        l.list_storage_location_slot = u_list_storage_location_storage_slot AND
        record_tags.record_version = 1 AND
        record_tags.record_type = 1;

    CREATE TEMPORARY TABLE temp_addr_follows (
        "user" types.eth_address,
        token_id types.efp_list_nft_token_id,
        record_version smallint,
        record_type smallint,
        record_data bytea,
        tags types.efp_tag[],
        updated_at TIMESTAMP WITH TIME ZONE
    ) ON COMMIT DROP;

    INSERT INTO temp_addr_follows SELECT
        l.user AS follower,
        l.token_id AS efp_list_nft_token_id,
        r.record_version,
        r.record_type,
        r.record_data,
        array_agg(t.tag) FILTER (WHERE t.tag IS NOT NULL) AS tags,
        r.updated_at
        
    FROM efp_list_records r
    LEFT JOIN efp_list_record_tags t ON r.chain_id::bigint = t.chain_id::bigint AND r.contract_address::text = t.contract_address::text AND r.slot::bytea = t.slot::bytea AND r.record = t.record
    JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
    JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
    
    WHERE
        -- only list record version 1
        r.record_version = 1 AND
        -- address record type (1)
        r.record_type = 1 AND
        -- match the address parameter
        r.record_data = addr_t_bytea AND
        -- Valid record data lookup
        l.user IS NOT NULL 
        -- -- NOT blocked
        -- t.tag != 'block' AND
        -- -- NOT muted
        -- t.tag != 'mute' 
    GROUP BY
        l.user,
        l.token_id,
        r.record_version,
        r.record_type,
        r.record_data,
        r.updated_at ;

RETURN QUERY
SELECT 
    public.hexlify(r.record_data)::types.eth_address as address,
    l.name,
    l.avatar,
    l.mutuals_rank as mutuals_rank
FROM temp_list_records r
INNER JOIN public.efp_leaderboard l ON l.address = public.hexlify(r.record_data)
    AND r.user = normalized_u_addr -- user 1
    AND r.has_block_tag = FALSE
    AND r.has_block_tag = FALSE
    AND EXISTS(
        SELECT 1
        FROM temp_addr_follows r2 
        WHERE r2.user = public.hexlify(r.record_data) 
    );
END;
$$;


--migrate:down