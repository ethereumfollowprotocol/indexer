-- migrate:up
-------------------------------------------------------------------------------
-- Function: handle_contract_event__UpdateListMetadata
-- Description: Inserts or updates a metadata value for a list. If a record
--              with the same chain_id, contract_address, and slot exists,
--              it updates the existing metadata value. Otherwise, it inserts
--              a new record into the list_metadata table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the list.
--   - p_slot (BIGINT): The slot associated with the list metadata.
--   - p_key (VARCHAR(255)): The metadata key.
--   - p_value (types.hexstring): The metadata value.
-- Returns: VOID
-- Notes: Uses the list_metadata table for storage.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__UpdateListMetadata (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_slot types.efp_list_storage_location_slot,
  p_key VARCHAR(255),
  p_value types.hexstring
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);

    -- Upsert metadata value
    INSERT INTO public.efp_list_metadata (chain_id, contract_address, slot, key, value)
    VALUES (p_chain_id, normalized_contract_address, p_slot, p_key, p_value)
    ON CONFLICT (chain_id, contract_address, slot, key)
    DO UPDATE SET value = EXCLUDED.value;

    -- if p_key is equal to "user", then update the user column of efp_lists for this list
    IF p_key = 'user' THEN
        UPDATE public.efp_lists l
        SET
            "user" = p_value
        WHERE
            l.list_storage_location_chain_id = p_chain_id
            AND l.list_storage_location_contract_address = normalized_contract_address
            AND l.list_storage_location_slot = p_slot;
    END IF;

    -- if p_key is equal to "manager", then update the manager column of efp_lists for this list
    IF p_key = 'manager' THEN
        UPDATE public.efp_lists l
        SET
            manager = p_value
        WHERE
            l.list_storage_location_chain_id = p_chain_id
            AND l.list_storage_location_contract_address = normalized_contract_address
            AND l.list_storage_location_slot = p_slot;
    END IF;
END;
$$;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: handle_contract_event__UpdateListMetadata
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS public.handle_contract_event__UpdateListMetadata (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_slot types.efp_list_storage_location_slot,
    p_key VARCHAR(255),
    p_value types.hexstring
  ) CASCADE;