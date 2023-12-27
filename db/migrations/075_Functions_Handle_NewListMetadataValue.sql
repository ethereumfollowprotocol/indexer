-- migrate:up



-------------------------------------------------------------------------------
-- Function: handle_contract_event__NewListMetadataValue
-- Description: Inserts or updates a metadata value for a list. If a record
--              with the same chain_id, contract_address, and nonce exists,
--              it updates the existing metadata value. Otherwise, it inserts
--              a new record into the list_metadata table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the list.
--   - p_nonce (BIGINT): The nonce associated with the list metadata.
--   - p_key (VARCHAR(255)): The metadata key.
--   - p_value (types.hexstring): The metadata value.
-- Returns: VOID
-- Notes: Uses the list_metadata table for storage.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__NewListMetadataValue(
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_nonce BIGINT,
    p_key VARCHAR(255),
    p_value types.hexstring
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);

    -- Upsert metadata value
    INSERT INTO public.list_metadata (chain_id, contract_address, nonce, key, value)
    VALUES (p_chain_id, normalized_contract_address, p_nonce, p_key, p_value)
    ON CONFLICT (chain_id, contract_address, nonce, key)
    DO UPDATE SET value = EXCLUDED.value;
END;
$$;



-- migrate:down
