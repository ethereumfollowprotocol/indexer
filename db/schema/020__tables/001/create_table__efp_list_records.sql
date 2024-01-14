-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_list_records
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_list_records (
    chain_id types.eth_chain_id NOT NULL,
    contract_address types.eth_address NOT NULL,
    slot types.efp_list_storage_location_slot NOT NULL,
    record BYTEA NOT NULL,
    record_version types.uint8 NOT NULL,
    record_type types.uint8 NOT NULL,
    record_data BYTEA NOT NULL,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (chain_id, contract_address, slot, record),
      FOREIGN KEY (chain_id, contract_address) REFERENCES public.contracts (chain_id, address)
  );



-- Index: index on chain_id, contract_address, slot, record_version, record_type
-- CREATE INDEX
--   idx_efp_list_records_on_filters ON public.efp_list_records (
--     chain_id,
--     contract_address,
--     slot,
--     record_version,
--     record_type,
--     record_data
--   );



CREATE TRIGGER
  update_efp_list_records_updated_at BEFORE
UPDATE
  ON public.efp_list_records FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();



-- migrate:down
DROP TABLE
  IF EXISTS public.efp_list_records CASCADE;