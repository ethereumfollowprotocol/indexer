-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_lists
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_lists (
    nft_chain_id types.eth_chain_id NOT NULL,
    nft_contract_address types.eth_address NOT NULL,
    token_id types.efp_list_nft_token_id NOT NULL,
    owner types.eth_address NOT NULL,
    manager types.eth_address NOT NULL,
    "user" types.eth_address NOT NULL,
    list_storage_location BYTEA,
    list_storage_location_chain_id BIGINT,
    list_storage_location_contract_address types.eth_address,
    list_storage_location_slot types.efp_list_storage_location_slot,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (nft_chain_id, nft_contract_address, token_id),
      FOREIGN KEY (nft_chain_id, nft_contract_address) REFERENCES public.contracts (chain_id, address)
      -- FOREIGN KEY (list_storage_location_chain_id, list_storage_location_contract_address) REFERENCES public.contracts (chain_id, address)
  );



CREATE TRIGGER
  update_efp_lists_updated_at BEFORE
UPDATE
  ON public.efp_lists FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_lists
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_lists CASCADE;