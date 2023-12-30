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
  chain_id types.eth_chain_id NOT NULL,
  address types.eth_address NOT NULL,
  name VARCHAR(255) NOT NULL,
  owner types.eth_address NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, address)
);



CREATE TRIGGER update_contracts_updated_at BEFORE
UPDATE ON public.contracts FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: account_metadata
-------------------------------------------------------------------------------
CREATE TABLE public.account_metadata (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  address types.eth_address NOT NULL,
  "key" VARCHAR(255) NOT NULL,
  value types.hexstring NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, address, "key"),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_account_metadata_updated_at BEFORE
UPDATE ON public.account_metadata FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: list_nfts
-------------------------------------------------------------------------------
CREATE TABLE public.list_nfts (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  token_id types.efp_list_nft_token_id NOT NULL,
  owner types.eth_address NOT NULL,
  -- TODO split out list storage location to separate table
  list_storage_location types.hexstring,
  list_storage_location_chain_id BIGINT,
  list_storage_location_contract_address types.eth_address,
  list_storage_location_nonce types.efp_list_storage_location_nonce,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, token_id),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_list_nfts_updated_at BEFORE
UPDATE ON public.list_nfts FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: list_metadata
-------------------------------------------------------------------------------
CREATE TABLE public.list_metadata (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  nonce types.efp_list_storage_location_nonce NOT NULL,
  "key" VARCHAR(255) NOT NULL,
  value types.hexstring NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, nonce, "key"),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_list_metadata_updated_at BEFORE
UPDATE ON public.list_metadata FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: list_ops
-------------------------------------------------------------------------------
CREATE TABLE public.list_ops (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  nonce types.efp_list_storage_location_nonce NOT NULL,
  op types.hexstring NOT NULL,
  version types.uint8 NOT NULL,
  opcode types.uint8 NOT NULL,
  data types.hexstring NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, nonce, op),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_list_ops_updated_at BEFORE
UPDATE ON public.list_ops FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: list_records
-------------------------------------------------------------------------------
CREATE TABLE public.list_records (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  nonce types.efp_list_storage_location_nonce NOT NULL,
  record types.hexstring NOT NULL,
  version types.uint8 NOT NULL,
  record_type types.uint8 NOT NULL,
  data types.hexstring NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, nonce, record),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_list_records_updated_at BEFORE
UPDATE ON public.list_records FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-------------------------------------------------------------------------------
-- Table: list_record_tags
-------------------------------------------------------------------------------
CREATE TABLE public.list_record_tags (
  chain_id types.eth_chain_id NOT NULL,
  contract_address types.eth_address NOT NULL,
  nonce types.efp_list_storage_location_nonce NOT NULL,
  record types.hexstring NOT NULL,
  tag types.efp_tag NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chain_id, contract_address, nonce, record, tag),
  FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
);



CREATE TRIGGER update_list_record_tags_updated_at BEFORE
UPDATE ON public.list_record_tags FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column ();



-- migrate:down
