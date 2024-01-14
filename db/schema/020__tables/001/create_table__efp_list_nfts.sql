-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_list_nfts
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_list_nfts (
    chain_id types.eth_chain_id NOT NULL,
    contract_address types.eth_address NOT NULL,
    token_id types.efp_list_nft_token_id NOT NULL,
    owner types.eth_address NOT NULL,
    -- list_storage_location BYTEA,
    -- list_storage_location_chain_id BIGINT,
    -- list_storage_location_contract_address types.eth_address,
    -- list_storage_location_slot types.efp_list_storage_location_slot,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (chain_id, contract_address, token_id),
      FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
  );



CREATE TRIGGER
  update_efp_list_nfts_updated_at BEFORE
UPDATE
  ON public.efp_list_nfts FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_list_nfts
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_list_nfts CASCADE;