--migrate:up
-------------------------------------------------------------------------------
-- Function: get_unique_followers
-- Description: Retrieves a distinct list of followers for a specified address,
--              de-duplicating by 'list_user'. This ensures each follower is
--              listed once, even if associated with multiple tokens.
-- Parameters:
--   - address (text): Address used to identify and filter followers.
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
OR REPLACE FUNCTION query.get_unique_followers(p_address VARCHAR(42)) RETURNS TABLE (
  follower types.eth_address,
  efp_list_nft_token_id types.efp_list_nft_token_id,
  tags types.efp_tag [],
  is_following BOOLEAN,
  is_blocked BOOLEAN,
  is_muted BOOLEAN,
  updated_at TIMESTAMP WITH TIME ZONE
) LANGUAGE plpgsql AS $$
DECLARE
    normalized_addr types.eth_address;
    addr_bytea bytea;
    primary_list_token_id BIGINT;
    t_list_storage_location_chain_id BIGINT;
    t_list_storage_location_contract_address VARCHAR(42);
    t_list_storage_location_storage_slot types.efp_list_storage_location_slot;
BEGIN
    -- Normalize the input address to lowercase
    normalized_addr := public.normalize_eth_address(p_address);
    addr_bytea := public.unhexlify(normalized_addr);

    -- Get the primary list token id
    SELECT v.primary_list_token_id
    INTO primary_list_token_id
    FROM public.view__events__efp_accounts_with_primary_list AS v
    WHERE v.address = normalized_addr;

    -- If no primary list token id is found, return an empty result set
    IF primary_list_token_id IS NOT NULL THEN

      -- Now determine the list storage location for the primary list token id
      SELECT
        v.efp_list_storage_location_chain_id,
        v.efp_list_storage_location_contract_address,
        v.efp_list_storage_location_slot
      INTO
        t_list_storage_location_chain_id,
        t_list_storage_location_contract_address,
        t_list_storage_location_storage_slot
      FROM
        public.view__events__efp_list_storage_locations AS v
      WHERE
        v.efp_list_nft_token_id = primary_list_token_id;

    END IF;

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
        l.list_storage_location_chain_id = t_list_storage_location_chain_id AND
        l.list_storage_location_contract_address = t_list_storage_location_contract_address AND
        l.list_storage_location_slot = t_list_storage_location_storage_slot AND
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
        r.record_data = addr_bytea AND
        -- Valid record data lookup
        l.user IS NOT NULL 
    GROUP BY
        l.user,
        l.token_id,
        r.record_version,
        r.record_type,
        r.record_data,
        r.updated_at ;

    RETURN QUERY
        SELECT
            v.user AS follower,
            v.token_id AS efp_list_nft_token_id,
            COALESCE(v.tags, '{}') AS tags,
            COALESCE(following_info.is_following, FALSE) AS is_following,
            COALESCE(following_info.is_blocked, FALSE) AS is_blocked,
            COALESCE(following_info.is_muted, FALSE) AS is_muted,
            v.updated_at
        FROM
            temp_addr_follows AS v
        LEFT JOIN LATERAL (
            SELECT
                NOT (following.has_block_tag OR following.has_mute_tag) AS is_following,
                following.has_block_tag AS is_blocked,
                following.has_mute_tag AS is_muted,
                following.updated_at AS updated_at
            FROM
                temp_list_records AS following
            WHERE
                public.is_valid_address(following.record_data) AND
                PUBLIC.hexlify(following.record_data)::types.eth_address = v.user
        ) AS following_info ON TRUE
        GROUP BY
            v.user,
            v.token_id,
            v.record_version,
            v.record_type,
            v.record_data,
            v.tags,
            v.updated_at,
            following_info.is_following,
            following_info.is_blocked,
            following_info.is_muted 
        ORDER BY
            v.user ASC;
END;
$$;



--migrate:down