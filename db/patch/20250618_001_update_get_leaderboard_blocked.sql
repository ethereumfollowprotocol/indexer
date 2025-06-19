-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_leaderboard_blocked
-- Description: This fix improves blocked lookups and adds ranks to the results. 
--              
---------------

DROP VIEW
    IF EXISTS PUBLIC.view__join__efp_leaderboard CASCADE;

DROP FUNCTION 
    IF EXISTS query.get_leaderboard_blocked(bigint);

DROP FUNCTION 
    IF EXISTS query.get_leaderboard_blocked_or_muted(bigint);

CREATE
OR REPLACE FUNCTION query.get_leaderboard_blocked (limit_count BIGINT) RETURNS TABLE (address types.eth_address, blocked_count BIGINT, blocked_rank BIGINT) LANGUAGE PLPGSQL AS $$
BEGIN
    CREATE TEMPORARY TABLE temp_leaderboard_blocked (
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

    INSERT INTO temp_leaderboard_blocked SELECT r.chain_id,
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
    WHERE t.tag = 'block'
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

    RETURN QUERY

    SELECT
        public.hexlify(v.record_data)::types.eth_address AS address,
        COUNT(DISTINCT v.user) AS blocked_count,
        RANK () OVER (
            ORDER BY COUNT(DISTINCT v.user) DESC NULLS LAST
        ) as blocked_rank
    FROM
        temp_leaderboard_blocked AS v
    WHERE
        -- only list record version 1
        v.record_version = 1 AND
        -- address record type (1)
        v.record_type = 1 AND
        -- -- valid address 
        public.is_valid_address(v.record_data) 
    GROUP BY
        v.record_data
    ORDER BY
        blocked_count DESC,
        v.record_data ASC
    LIMIT limit_count;
END;
$$;

--migrate:down