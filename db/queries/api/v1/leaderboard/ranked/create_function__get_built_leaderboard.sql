--migrate:up
-------------------------------------------------------------------------------
-- Function: get_built_leaderboard
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_built_leaderboard () RETURNS TABLE (
  address types.eth_address,
  name text,
  avatar text,
  header text,
  mutuals_rank BIGINT,
  followers_rank BIGINT,
  following_rank BIGINT,
  blocks_rank BIGINT,
  top8_rank BIGINT,
  mutuals BIGINT,
  following BIGINT,
  followers BIGINT,
  blocks BIGINT,
  top8 BIGINT
) LANGUAGE plpgsql AS $$

BEGIN

-- build a table of all list records with tags 
        CREATE TEMPORARY TABLE temp_all_records (
        nft_chain_id bigint,
        nft_contract_address varchar(42),
        token_id bigint,
        owner varchar(42),
        manager varchar(42),
        "user" varchar(42),
        record_data bytea,
		record_version smallint,
        record_type smallint,
        tags types.efp_tag[]       
    ) ON COMMIT DROP;

	INSERT INTO temp_all_records SELECT r.chain_id,
        r.contract_address,
        l.token_id,
		l.owner,
		l.manager,
		l."user",
		r.record_data,
		r.record_version,
        r.record_type,
        array_agg(t.tag) FILTER (WHERE t.tag IS NOT NULL) AS tags
    FROM efp_list_records r
    LEFT JOIN efp_list_record_tags t ON r.chain_id::bigint = t.chain_id::bigint AND r.contract_address::text = t.contract_address::text AND r.slot::bytea = t.slot::bytea AND r.record = t.record
	JOIN view__join__efp_lists_with_metadata l ON l.list_storage_location_chain_id = r.chain_id::bigint AND l.list_storage_location_contract_address::text = r.contract_address::text AND l.list_storage_location_slot::bytea = r.slot::bytea
    JOIN efp_account_metadata meta ON l."user"::text = meta.address::text AND l.token_id::bigint = convert_hex_to_bigint(meta.value::text)
    GROUP BY 
		r.chain_id, 
		r.contract_address, 
		l.token_id,
		l.owner,
		l.manager,
		l."user",
		r.record_version, 
		r.record_type, 
		r.record_data;

-- ranked by followers
	CREATE TEMPORARY TABLE temp_leaderboard_followers (
        address types.eth_address, 
        followers_count BIGINT,
        followers_rank BIGINT,
        PRIMARY KEY (address)
    ) ON COMMIT DROP;

    INSERT INTO temp_leaderboard_followers     SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS followers_count,
        RANK () OVER (
            ORDER BY COUNT(DISTINCT v.user) DESC NULLS LAST
        ) as followers_rank
    FROM
        temp_all_records AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.record_data)
    GROUP BY
        v.record_data
    ORDER BY
        followers_count DESC,
        v.record_data ASC;

-- ranked by following
    CREATE TEMPORARY TABLE temp_leaderboard_following (
        address types.eth_address, 
        following_count BIGINT,
        following_rank BIGINT,
        PRIMARY KEY (address)
    ) ON COMMIT DROP;

    INSERT INTO temp_leaderboard_following SELECT
        v.user AS address,
        COUNT(DISTINCT v.record_data) AS following_count,
        RANK () OVER (
            ORDER BY COUNT(DISTINCT v.record_data) DESC NULLS LAST
        ) as following_rank
    FROM
        temp_all_records AS v
    WHERE
        -- only version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.record_data)
    GROUP BY
        v.user
    ORDER BY
        following_count DESC,
        v.user ASC;

-- ranked by blocked
    CREATE TEMPORARY TABLE temp_leaderboard_blocked (
        address types.eth_address, 
        blocked_count BIGINT,
        blocked_rank BIGINT,
        PRIMARY KEY (address)
    ) ON COMMIT DROP;

    INSERT INTO temp_leaderboard_blocked SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS blocked_count,
        RANK () OVER (
            ORDER BY COUNT(DISTINCT v.user) DESC NULLS LAST
        ) as blocked_rank
    FROM
        temp_all_records AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- valid address format
        public.is_valid_address(v.record_data) AND
        -- blocked
        v.tags && array['block']::types.efp_tag[]
    GROUP BY
        v.record_data
    ORDER BY
        blocked_count DESC,
        v.record_data ASC;

-- ranked by top8
    CREATE TEMPORARY TABLE temp_leaderboard_top8 (
        address types.eth_address, 
        top8_count BIGINT,
        top8_rank BIGINT,
        PRIMARY KEY (address)
    ) ON COMMIT DROP;

    INSERT INTO temp_leaderboard_top8 SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS top8_count,
        RANK () OVER (
            ORDER BY COUNT(DISTINCT v.user) DESC NULLS LAST
        ) as top8_rank
    FROM
        temp_all_records AS v
    WHERE
        v.record_version = 1 AND
        v.record_type = 1 AND
        public.is_valid_address(v.record_data) AND
        v.tags && array['top8']::types.efp_tag[]
    GROUP BY
        v.record_data
    ORDER BY
        top8_count DESC,
        v.record_data ASC;

    RETURN QUERY
        SELECT efp.address,
        COALESCE(ens.name) AS ens_name,
        COALESCE(ens.avatar) AS ens_avatar,
        REPLACE(ens.records->>'header', '"', '') as header, 
        mut.mutuals_rank,
        fers.followers_rank,
        fing.following_rank,
        blocks.blocked_rank AS blocks_rank,
        top8.top8_rank,
        COALESCE(mut.mutuals, 0::bigint) AS mutuals,
		COALESCE(fing.following_count, 0::bigint) AS following,
        COALESCE(fers.followers_count, 0::bigint) AS followers,
        COALESCE(blocks.blocked_count, 0::bigint) AS blocks,
        COALESCE(top8.top8_count, 0::bigint) AS top8
    FROM efp_addresses efp  
    LEFT JOIN temp_leaderboard_followers fers(address, followers_count) ON fers.address::text = efp.address::text
    LEFT JOIN temp_leaderboard_following fing(address, following_count) ON fing.address::text = efp.address::text
    LEFT JOIN temp_leaderboard_blocked blocks(address, blocked_count) ON blocks.address::text = efp.address::text
    LEFT JOIN temp_leaderboard_top8 top8(address, top8_count) ON top8.address::text = efp.address::text
    LEFT JOIN public.efp_mutuals mut ON mut.address::text = efp.address::text
    LEFT JOIN ens_metadata ens ON ens.address::text = efp.address::text
    ORDER BY mut.mutuals DESC NULLS LAST;
END;
$$;




--migrate:down