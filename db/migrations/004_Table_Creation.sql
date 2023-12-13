-- migrate:up

-- Table Creation: Define all necessary tables

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE
    public.contracts (
        chain_id bigint NOT NULL,
        address character varying(42) NOT NULL,
        name character varying(255) NOT NULL,
        owner character varying(42) NOT NULL,
        PRIMARY KEY (chain_id, address)
    );

CREATE TABLE
    public.events (
        id text DEFAULT public.generate_ulid() NOT NULL,
        transaction_hash character varying(66) NOT NULL,
        block_number bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        event_name character varying(255) NOT NULL,
        event_parameters jsonb NOT NULL,
        "timestamp" timestamp
        with
            time zone NOT NULL,
            processed text DEFAULT 'false' :: text NOT NULL
    );

CREATE TABLE
    public.account_metadata (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        address character varying(42) NOT NULL,
        key character varying(255) NOT NULL,
        value character varying(255) NOT NULL,
        PRIMARY KEY (
            chain_id,
            contract_address,
            address,
            key
        )
    );

CREATE TABLE
    public.list_nfts (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        token_id bigint NOT NULL,
        owner character varying(42) NOT NULL,
        list_manager character varying(42),
        -- list_user character varying(42),
        list_storage_location character varying(255),
        list_storage_location_chain_id BIGINT,
        list_storage_location_contract_address character varying(42),
        list_storage_location_nonce bigint,
        PRIMARY KEY (
            chain_id,
            contract_address,
            token_id
        )
    );

CREATE TABLE
    public.list_metadata (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        nonce bigint NOT NULL,
        key character varying(255) NOT NULL,
        value character varying(255) NOT NULL,
        PRIMARY KEY (
            chain_id,
            contract_address,
            nonce,
            key
        )
    );

-- combine list_nfts with "user" metadata

CREATE VIEW
    public.list_nfts_view AS -- list_nfts JOIN ed with list_metadata WHERE key ="user"
SELECT
    nfts.*,
    lm.value AS list_user
FROM public.list_nfts AS nfts
    LEFT JOIN public.list_metadata AS lm ON lm.chain_id = nfts.list_storage_location_chain_id AND lm.contract_address = nfts.list_storage_location_contract_address AND lm.nonce = nfts.list_storage_location_nonce AND lm.key = 'user';

CREATE TABLE
    public.list_ops (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        nonce bigint NOT NULL,
        op character varying(255) NOT NULL,
        version smallint NOT NULL,
        CHECK (
            version >= 0
            AND version <= 255
        ),
        code smallint NOT NULL,
        CHECK (
            code >= 0
            AND code <= 255
        ),
        data character varying(255) NOT NULL,
        PRIMARY KEY (
            chain_id,
            contract_address,
            nonce,
            op
        )
    );

CREATE TABLE
    public.list_records (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        nonce bigint NOT NULL,
        record character varying(255) NOT NULL,
        version smallint NOT NULL,
        CHECK (
            version >= 0
            AND version <= 255
        ),
        type smallint NOT NULL,
        CHECK (
            type >= 0
            AND type <= 255
        ),
        data character varying(255) NOT NULL,
        PRIMARY KEY (
            chain_id,
            contract_address,
            nonce,
            record
        )
    );

CREATE TABLE
    public.list_record_tags (
        chain_id bigint NOT NULL,
        contract_address character varying(42) NOT NULL,
        nonce bigint NOT NULL,
        record character varying(255) NOT NULL,
        tag character varying(255) NOT NULL,
        PRIMARY KEY (
            chain_id,
            contract_address,
            nonce,
            record,
            tag
        )
    );

CREATE VIEW
    public.list_records_tags_view AS
SELECT
    records.chain_id,
    records.contract_address,
    records.nonce,
    records.record,
    records.version,
    records.type,
    records.data,
    array_agg(tags.tag) AS tags
FROM
    public.list_records AS records
    LEFT JOIN public.list_record_tags AS tags ON tags.chain_id = records.chain_id
    AND tags.contract_address = records.contract_address
    AND tags.nonce = records.nonce
    AND tags.record = records.record
GROUP BY
    records.chain_id,
    records.contract_address,
    records.nonce,
    records.record,
    records.version,
    records.type,
    records.data;

CREATE VIEW
    public.list_records_tags_extended_view AS
SELECT
    nft.token_id,
    nft.list_user,
    nft.list_storage_location_chain_id,
    nft.list_storage_location_contract_address,
    nft.list_storage_location_nonce,
    v.record,
    v.version,
    v.type,
    v.data,
    v.tags,
    CASE
        WHEN 'block' = ANY(v.tags) THEN TRUE
        ELSE FALSE
    END AS has_block_tag,
    CASE
        WHEN 'mute' = ANY(v.tags) THEN TRUE
        ELSE FALSE
    END AS has_mute_tag
FROM
    public.list_records_tags_view AS v
    LEFT JOIN public.list_nfts_view AS nft ON nft.list_storage_location_chain_id = v.chain_id
    AND nft.list_storage_location_contract_address = v.contract_address
    AND nft.list_storage_location_nonce = v.nonce;

-- migrate:down