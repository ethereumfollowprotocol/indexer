-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__UpdateAccountMetadata
-- Description: Inserts or updates an account metadata value. If a record with
--              the same chain_id, contract_address, address, and key exists,
--              it updates the existing metadata value. Otherwise, it inserts
--              a new record into the efp_account_metadata table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the metadata.
--   - p_address (VARCHAR(42)): The account address associated with the metadata.
--   - p_key (VARCHAR(255)): The metadata key.
--   - p_value (VARCHAR(255)): The metadata value.
-- Returns: VOID
-- Notes: Uses the efp_account_metadata table for storage.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__UpdateAccountMetadata (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_address VARCHAR(42),
  p_key VARCHAR(255),
  p_value VARCHAR(255)
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_address types.eth_address;
BEGIN

    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_address := public.normalize_eth_address(p_address);

    -- Upsert metadata value
    INSERT INTO public.efp_account_metadata (chain_id, contract_address, address, key, value)
    VALUES (p_chain_id, normalized_contract_address, normalized_address, p_key, p_value)
    ON CONFLICT (chain_id, contract_address, address, key)
    DO UPDATE SET value = EXCLUDED.value;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__UpdateAccountMetadata
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__UpdateAccountMetadata (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_address VARCHAR(42),
    p_key VARCHAR(255),
    p_value VARCHAR(255)
  ) CASCADE;