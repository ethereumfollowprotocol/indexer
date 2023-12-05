-- migrate:up

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';

--
-- Name: action; Type: TYPE; Schema: public; Owner: -
--

DROP TYPE IF EXISTS public.action;
CREATE TYPE public.action AS ENUM (
    'follow',
    'unfollow',
    'block',
    'unblock',
    'mute',
    'unmute'
);


--
-- Name: generate_ulid(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION public.generate_ulid() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- Crockford's Base32
  encoding   BYTEA = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  timestamp  BYTEA = E'\\000\\000\\000\\000\\000\\000';
  output     TEXT = '';

  unix_time  BIGINT;
  ulid       BYTEA;
BEGIN
  -- 6 timestamp bytes
  unix_time = (EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000)::BIGINT;
  timestamp = SET_BYTE(timestamp, 0, (unix_time >> 40)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 1, (unix_time >> 32)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 2, (unix_time >> 24)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 3, (unix_time >> 16)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 4, (unix_time >> 8)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 5, unix_time::BIT(8)::INTEGER);

  -- 10 entropy bytes
  ulid = timestamp || gen_random_bytes(10);

  -- Encode the timestamp
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 0) & 224) >> 5));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 0) & 31)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 1) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 1) & 7) << 2) | ((GET_BYTE(ulid, 2) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 2) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 2) & 1) << 4) | ((GET_BYTE(ulid, 3) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 3) & 15) << 1) | ((GET_BYTE(ulid, 4) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 4) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 4) & 3) << 3) | ((GET_BYTE(ulid, 5) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 5) & 31)));

  -- Encode the entropy
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 6) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 6) & 7) << 2) | ((GET_BYTE(ulid, 7) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 7) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 7) & 1) << 4) | ((GET_BYTE(ulid, 8) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 8) & 15) << 1) | ((GET_BYTE(ulid, 9) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 9) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 9) & 3) << 3) | ((GET_BYTE(ulid, 10) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 10) & 31)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 11) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 11) & 7) << 2) | ((GET_BYTE(ulid, 12) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 12) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 12) & 1) << 4) | ((GET_BYTE(ulid, 13) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 13) & 15) << 1) | ((GET_BYTE(ulid, 14) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 14) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 14) & 3) << 3) | ((GET_BYTE(ulid, 15) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 15) & 31)));

  RETURN output;
END
$$;


--
-- Name: get_followers(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_followers(target_address character varying) RETURNS TABLE(actor_address character varying, action_timestamp timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
RETURN QUERY
SELECT t.actor_address, t.action_timestamp, t.created_at
FROM (
    SELECT a.actor_address, a.action_timestamp, a.created_at, a.action,
           ROW_NUMBER() OVER (PARTITION BY a.actor_address ORDER BY a.action_timestamp DESC) as rn
    FROM activity a
    WHERE a.target_address = get_followers.target_address
    AND a.action IN ('follow', 'unfollow')
) t
WHERE t.rn = 1 AND t.action = 'follow';
END; $$;


--
-- Name: get_following(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_following(actor_address character varying) RETURNS TABLE(target_address character varying, action_timestamp timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN QUERY
SELECT t.target_address, t.action_timestamp, t.created_at
FROM (
    SELECT a.target_address, a.action_timestamp, a.created_at, a.action,
           ROW_NUMBER() OVER (PARTITION BY a.target_address ORDER BY a.action_timestamp DESC) as rn
    FROM activity a
    WHERE a.actor_address = get_following.actor_address
    AND a.action IN ('follow', 'unfollow')
) t
WHERE t.rn = 1 AND t.action = 'follow';
END; $$;


--
-- Name: health(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.health() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
   RETURN 'ok';
END;
$$;


--
-- Name: insert_user_if_not_exists(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_user_if_not_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM "user" WHERE wallet_address = NEW.actor_address) THEN
        INSERT INTO "user" (wallet_address) VALUES (NEW.actor_address);
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity (
    id text DEFAULT public.generate_ulid() NOT NULL,
    action public.action NOT NULL,
    actor_address character varying NOT NULL,
    target_address character varying NOT NULL,
    action_timestamp timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    updated_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id text DEFAULT public.generate_ulid() NOT NULL,
    transaction_hash character varying(66) NOT NULL,
    block_number bigint NOT NULL,
    contract_address character varying(42) NOT NULL,
    event_name character varying(255) NOT NULL,
    event_parameters jsonb NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    processed text DEFAULT 'false'::text NOT NULL
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id text DEFAULT public.generate_ulid() NOT NULL,
    wallet_address character varying NOT NULL,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    updated_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);

--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user user_wallet_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_wallet_address_key UNIQUE (wallet_address);


--
-- Name: idx_block_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_block_number ON public.events USING btree (block_number);


--
-- Name: idx_contract_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contract_address ON public.events USING btree (contract_address);


--
-- Name: idx_event_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_event_name ON public.events USING btree (event_name);


--
-- Name: idx_transaction_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_hash ON public.events USING btree (transaction_hash);


--
-- Name: index_activity_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_action ON public.activity USING btree (action);


--
-- Name: index_activity_actor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_actor ON public.activity USING btree (actor_address);


--
-- Name: index_activity_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_target ON public.activity USING btree (target_address);


--
-- Name: activity activity_insert_user; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER activity_insert_user BEFORE INSERT ON public.activity FOR EACH ROW EXECUTE FUNCTION public.insert_user_if_not_exists();


--
-- Name: activity activity_actor_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_actor_address_fkey FOREIGN KEY (actor_address) REFERENCES public."user"(wallet_address) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: activity activity_actor_address_user_wallet_address_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_actor_address_user_wallet_address_fk FOREIGN KEY (actor_address) REFERENCES public."user"(wallet_address) ON UPDATE CASCADE ON DELETE RESTRICT;

-- migrate:down

