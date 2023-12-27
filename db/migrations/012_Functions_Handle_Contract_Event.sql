-- migrate:up



-------------------------------------------------------------------------------
-- Function: handle_contract_event__NewAccountMetadataValue
-- Description: Inserts or updates an account metadata value. If a record with
--              the same chain_id, contract_address, address, and key exists,
--              it updates the existing metadata value. Otherwise, it inserts
--              a new record into the account_metadata table.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address associated with
--                                        the metadata.
--   - p_address (VARCHAR(42)): The account address associated with the metadata.
--   - p_key (VARCHAR(255)): The metadata key.
--   - p_value (VARCHAR(255)): The metadata value.
-- Returns: VOID
-- Notes: Uses the account_metadata table for storage.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__NewAccountMetadataValue(
  p_chain_id BIGINT,
  p_contract_address VARCHAR(42),
  p_address VARCHAR(42),
  p_key VARCHAR(255),
  p_value VARCHAR(255)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_address types.eth_address;
BEGIN

    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_address := public.normalize_eth_address(p_address);

    -- Upsert metadata value
    INSERT INTO account_metadata (chain_id, contract_address, address, key, value)
    VALUES (p_chain_id, normalized_contract_address, normalized_address, p_key, p_value)
    ON CONFLICT (chain_id, contract_address, address, key)
    DO UPDATE SET value = EXCLUDED.value;
END;
$$;



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
CREATE OR REPLACE FUNCTION public.handle_contract_event__OwnershipTransferred(
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_contract_name VARCHAR(255),
    p_previous_owner VARCHAR(42),
    p_new_owner VARCHAR(42)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_previous_owner types.eth_address;
    normalized_new_owner types.eth_address;
BEGIN
    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_new_owner := public.normalize_eth_address(p_new_owner);

    IF p_previous_owner = '0x0000000000000000000000000000000000000000' THEN
        -- Check for duplicate contract
        IF EXISTS (
            SELECT 1 FROM public.contracts c
            WHERE c.chain_id = p_chain_id
            AND c.address = normalized_contract_address
        ) THEN
            RAISE EXCEPTION 'Attempt to insert duplicate contract (chain_id=%, address=%) with name %', p_chain_id, p_contract_address, p_contract_name;
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
            RAISE EXCEPTION 'Previous owner does not match for contract (chain_id=%, address=%, expected_previous_owner=%)', p_chain_id, p_contract_address, p_previous_owner;
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
-- Function: handle_contract_event__Transfer
-- Description: Processes a transfer event by either inserting a new NFT into
--              the list_nfts table or updating the owner of an existing NFT.
--              It throws an error if a duplicate insertion is attempted for a
--              new NFT (identified by 'from' address being '0x0'). For updates,
--              it changes the owner of the NFT to the 'to' address.
-- Parameters:
--   - p_chain_id (BIGINT): The blockchain network identifier.
--   - p_contract_address (VARCHAR(42)): The contract address of the NFT.
--   - p_token_id (BIGINT): The unique identifier of the NFT.
--   - p_from_address (VARCHAR(42)): The sender's address of the transfer.
--   - p_to_address (VARCHAR(42)): The receiver's address of the transfer.
-- Returns: VOID
-- Notes: Addresses are normalized to lowercase. Uses the list_nfts table for
--        storage. Relies on external normalization functions for address
--        format validation.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_contract_event__Transfer(
    p_chain_id BIGINT,
    p_contract_address VARCHAR(42),
    p_token_id BIGINT,
    p_from_address VARCHAR(42),
    p_to_address VARCHAR(42)
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    normalized_contract_address types.eth_address;
    normalized_from_address types.eth_address;
    normalized_to_address types.eth_address;
BEGIN

    -- Normalize the input addresses to lowercase
    normalized_contract_address := public.normalize_eth_address(p_contract_address);
    normalized_to_address := public.normalize_eth_address(p_to_address);

    IF p_from_address = '0x0000000000000000000000000000000000000000' THEN
        -- Attempt to insert new row
        IF EXISTS (
            SELECT 1 FROM public.list_nfts nft
            WHERE nft.chain_id = p_chain_id
            AND nft.contract_address = normalized_contract_address
            AND nft.token_id = p_token_id
        ) THEN
            RAISE EXCEPTION 'Attempt to insert duplicate list_nfts row (chain_id=%, contract_address=%, token_id=%)', p_chain_id, p_contract_address, p_token_id;
        END IF;

        -- Insert new row
        INSERT INTO public.list_nfts (chain_id, contract_address, token_id, owner)
        VALUES (p_chain_id, normalized_contract_address, p_token_id, normalized_to_address)
        ON CONFLICT (chain_id, contract_address, token_id) DO NOTHING;

    ELSE
        -- Update existing row
        UPDATE public.list_nfts as nft
        SET nft.owner = normalized_to_address
        WHERE nft.chain_id = p_chain_id
        AND nft.contract_address = normalized_contract_address
        AND nft.token_id = p_token_id;

    END IF;
END;
$$;

-- migrate:down
