-- migrate:up
-------------------------------------------------------------------------------
-- Table: contracts
-------------------------------------------------------------------------------
CREATE TABLE
  public.contracts (
    chain_id types.eth_chain_id NOT NULL,
    address types.eth_address NOT NULL,
    name VARCHAR(255),
    owner types.eth_address NOT NULL,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (chain_id, address)
  );



-------------------------------------------------------------------------------
-- Function: handle_contract_event__OwnershipTransferred
-- Description: Processes an ownership transferred event by either inserting a
--              new contract into the contracts table or updating the owner of
--              an existing contract. It throws an error if a duplicate
--              insertion is attempted for a new contract (identified by the
--              'previousOwner' being '0x0'). For updates, it changes the
--              owner of the contract to the 'newOwner'.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address.
--   - p_contract_name (VARCHAR(255)): The name of the contract.
--   - p_previous_owner (VARCHAR(42)): The previous owner's address.
--   - p_new_owner (VARCHAR(42)): The new owner's address.
-- Returns: VOID
-- Notes: Addresses are normalized to lowercase. Relies on external
--        normalization functions for address format validation. Uses the
--        contracts table for storage.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.handle_contract_event__OwnershipTransferred (
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_contract_name VARCHAR(255),
  p_previous_owner VARCHAR(42),
  p_new_owner VARCHAR(42)
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_previous_owner types.eth_address;
    normalized_new_owner types.eth_address;
BEGIN
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_new_owner := public.normalize_eth_address(p_new_owner);

    IF p_previous_owner = '0x0000000000000000000000000000000000000000' THEN
        -- Check for duplicate contract
        IF EXISTS (
            SELECT 1 FROM public.contracts c
            WHERE c.chain_id = p_chain_id
            AND c.address = normalized_contract_address
        ) THEN
            RAISE EXCEPTION 'Attempt to insert duplicate contract (chain_id=%, address=%) with name=%, previous_owner=%, new_owner=%',
                p_chain_id,
                normalized_contract_address,
                p_contract_name,
                p_previous_owner,
                p_new_owner;
        END IF;

        -- Insert new contract
        INSERT INTO public.contracts (chain_id, address, name, owner)
        VALUES (p_chain_id, normalized_contract_address, p_contract_name, normalized_new_owner);

    ELSE
        normalized_previous_owner := public.normalize_eth_address(p_previous_owner);

        -- Validate previous owner
        IF NOT EXISTS (
            SELECT 1 FROM public.contracts c
            WHERE c.chain_id = p_chain_id
            AND c.address = normalized_contract_address
            AND c.owner = normalized_previous_owner
        ) THEN
            RAISE EXCEPTION 'Previous owner does not match for contract (chain_id=%, address=%, expected_previous_owner=%)',
                p_chain_id,
                normalized_contract_address,
                normalized_previous_owner;
        END IF;

        -- Update existing contract owner
        UPDATE public.contracts c
        SET owner = normalized_new_owner
        WHERE c.chain_id = p_chain_id
        AND c.address = normalized_contract_address;

    END IF;
END;
$$;



-------------------------------------------------------------------------------
-- Triggers
-------------------------------------------------------------------------------
CREATE TRIGGER
  update_contracts_updated_at BEFORE
UPDATE
  ON public.contracts FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column ();



-- migrate:down
DROP FUNCTION
  IF EXISTS public.handle_contract_event__OwnershipTransferred (
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_contract_name VARCHAR(255),
    p_previous_owner VARCHAR(42),
    p_new_owner VARCHAR(42)
  );



DROP TABLE
  IF EXISTS public.contracts CASCADE;



DROP TRIGGER
  IF EXISTS update_contracts_updated_at ON public.contracts;