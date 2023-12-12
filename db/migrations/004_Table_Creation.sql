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
        list_user character varying(42),
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
    public.list_records_view AS
SELECT
    chain_id,
    contract_address,
    nonce,
    record,
    array_agg(tag) AS tags
FROM public.list_record_tags
    INNER JOIN public.list_records USING (
        chain_id, contract_address, nonce, record
    )
GROUP BY
    chain_id,
    contract_address,
    nonce,
    record;

CREATE SEQUENCE
    public.events_id_seq AS integer START
WITH
    1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;

ALTER TABLE ONLY public.events
ADD
    CONSTRAINT events_pkey PRIMARY KEY (id);

CREATE INDEX
    idx_block_number ON public.events USING btree (block_number);

CREATE INDEX
    idx_contract_address ON public.events USING btree (contract_address);

CREATE INDEX
    idx_event_name ON public.events USING btree (event_name);

--

-- Name: idx_transaction_hash; Type: INDEX; Schema: public; Owner: -

--

CREATE INDEX
    idx_transaction_hash ON public.events USING btree (transaction_hash);

-- migrate:down