-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_list_ops
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_list_ops (
    chain_id types.eth_chain_id NOT NULL,
    contract_address types.eth_address NOT NULL,
    slot types.efp_list_storage_location_slot NOT NULL,
    op types.hexstring NOT NULL,
    version types.uint8 NOT NULL,
    opcode types.uint8 NOT NULL,
    data types.hexstring NOT NULL,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (chain_id, contract_address, slot, op),
      FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
  );



CREATE TRIGGER
  update_efp_list_ops_updated_at BEFORE
UPDATE
  ON public.efp_list_ops FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_list_ops
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_list_ops CASCADE;