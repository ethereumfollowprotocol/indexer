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
  is_muted BOOLEAN
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

    -- TODO: left join below query against the following query to determine if:
    --       - (following) the follower is an unblocked+unmuted list record of by the primary list of p_address
    --       - (blocked)  the follower is blocked on the primary list of p_address
    --       - (muted)    the follower is muted on the primary list of p_address

     RETURN QUERY
    SELECT
        v.user AS follower,
        v.token_id AS efp_list_nft_token_id,
        COALESCE(v.tags, '{}') AS tags,
        COALESCE(following_info.is_following, FALSE) AS is_following,
        COALESCE(following_info.is_blocked, FALSE) AS is_blocked,
        COALESCE(following_info.is_muted, FALSE) AS is_muted
    FROM
        public.view__join__efp_list_records_with_nft_manager_user_tags AS v
    LEFT JOIN LATERAL (
        SELECT
            NOT (following.has_block_tag OR following.has_mute_tag) AS is_following,
            following.has_block_tag AS is_blocked,
            following.has_mute_tag AS is_muted
        FROM
            public.view__join__efp_list_records_with_nft_manager_user_tags AS following
        WHERE
            following.list_storage_location_chain_id = t_list_storage_location_chain_id AND
            following.list_storage_location_contract_address = t_list_storage_location_contract_address AND
            following.list_storage_location_slot = t_list_storage_location_storage_slot AND
            following.record_version = 1 AND
            following.record_type = 1 AND
            public.is_valid_address(following.record_data) AND
            PUBLIC.hexlify(following.record_data)::types.eth_address = v.user
    ) AS following_info ON TRUE
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- match the address parameter
        v.record_data = addr_bytea AND
        -- NOT blocked
        v.has_block_tag = FALSE AND
        -- NOT muted
        v.has_mute_tag = FALSE
    GROUP BY
        v.user,
        v.token_id,
        v.record_version,
        v.record_type,
        v.record_data,
        v.tags,
        following_info.is_following,
        following_info.is_blocked,
        following_info.is_muted
    HAVING
        (SELECT get_primary_list FROM query.get_primary_list(v.user)) = v.token_id
    ORDER BY
        v.user ASC;
END;
$$;



--migrate:down