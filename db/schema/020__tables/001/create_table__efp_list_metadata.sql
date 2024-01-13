-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_list_metadata
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_list_metadata (
    chain_id types.eth_chain_id NOT NULL,
    contract_address types.eth_address NOT NULL,
    slot types.efp_list_storage_location_slot NOT NULL,
    "key" VARCHAR(255) NOT NULL,
    value types.hexstring NOT NULL,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (chain_id, contract_address, slot, "key"),
      FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
  );



CREATE TRIGGER
  update_efp_list_metadata_updated_at BEFORE
UPDATE
  ON public.efp_list_metadata FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_list_metadata
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_list_metadata CASCADE;