-- migrate:up
-- Table Creation: Define all necessary tables
SET
  default_tablespace = '';

SET
  default_table_access_method = HEAP;

-------------------------------------------------------------------------------
-- Table: contracts
-------------------------------------------------------------------------------
CREATE TABLE public.contracts (
  chain_id bigint NOT NULL,
  address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(address)),
  name character varying(255) NOT NULL,
  owner character varying(42) NOT NULL,
  CHECK (public.is_valid_address(owner)),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, address)
);

CREATE TRIGGER update_contracts_updated_at BEFORE
UPDATE
  ON public.contracts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: events
-------------------------------------------------------------------------------
CREATE TABLE public.events (
  id text DEFAULT public.generate_ulid() NOT NULL,
  transaction_hash character varying(66) NOT NULL,
  block_number bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  event_name character varying(255) NOT NULL,
  event_parameters jsonb NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_events_updated_at BEFORE
UPDATE
  ON public.events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: account_metadata
-------------------------------------------------------------------------------
CREATE TABLE public.account_metadata (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(address)),
  "key" character varying(255) NOT NULL,
  value character varying(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    address,
    "key"
  )
);

CREATE TRIGGER update_account_metadata_updated_at BEFORE
UPDATE
  ON public.account_metadata FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: list_nfts
-------------------------------------------------------------------------------
CREATE TABLE public.list_nfts (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL CHECK (public.is_valid_address(contract_address)),
  token_id bigint NOT NULL,
  owner character varying(42) NOT NULL,
  CHECK (public.is_valid_address(owner)),
  list_storage_location character varying(255),
  CHECK (public.is_hexstring(list_storage_location)),
  list_storage_location_chain_id BIGINT,
  list_storage_location_contract_address character varying(42),
  CHECK (
    public.is_valid_address(list_storage_location_contract_address)
  ),
  list_storage_location_nonce bigint,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    token_id
  )
);

CREATE TRIGGER update_list_nfts_updated_at BEFORE
UPDATE
  ON public.list_nfts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: list_metadata
-------------------------------------------------------------------------------
CREATE TABLE public.list_metadata (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  nonce bigint NOT NULL,
  "key" character varying(255) NOT NULL,
  value character varying(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    nonce,
    "key"
  )
);

CREATE TRIGGER update_list_metadata_updated_at BEFORE
UPDATE
  ON public.list_metadata FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: list_ops
-------------------------------------------------------------------------------
CREATE TABLE public.list_ops (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  nonce bigint NOT NULL,
  op character varying(255) NOT NULL,
  CHECK (public.is_hexstring(op)),
  version smallint NOT NULL,
  CHECK (public.is_uint8(version)),
  opcode smallint NOT NULL,
  CHECK (public.is_uint8(opcode)),
  data character varying(255) NOT NULL,
  CHECK (public.is_hexstring(data)),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    nonce,
    op
  )
);

CREATE TRIGGER update_list_ops_updated_at BEFORE
UPDATE
  ON public.list_ops FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: list_records
-------------------------------------------------------------------------------
CREATE TABLE public.list_records (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  nonce bigint NOT NULL,
  record character varying(255) NOT NULL,
  CHECK (public.is_hexstring(record)),
  version smallint NOT NULL,
  CHECK (public.is_uint8(version)),
  record_type smallint NOT NULL,
  CHECK (public.is_uint8(record_type)),
  data character varying(255) NOT NULL,
  CHECK (public.is_hexstring(data)),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    nonce,
    record
  )
);

CREATE TRIGGER update_list_records_updated_at BEFORE
UPDATE
  ON public.list_records FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------------------------------------
-- Table: list_record_tags
-------------------------------------------------------------------------------
CREATE TABLE public.list_record_tags (
  chain_id bigint NOT NULL,
  contract_address character varying(42) NOT NULL,
  CHECK (public.is_valid_address(contract_address)),
  nonce bigint NOT NULL,
  record character varying(255) NOT NULL,
  CHECK (public.is_hexstring(record)),
  tag character varying(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (
    chain_id,
    contract_address,
    nonce,
    record,
    tag
  )
);

CREATE TRIGGER update_list_record_tags_updated_at BEFORE
UPDATE
  ON public.list_record_tags FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- migrate:down