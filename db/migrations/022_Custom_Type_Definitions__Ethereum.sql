-- migrate:up
-- Custom Type Definitions

-------------------------------------------------------------------------------
-- Domain: types.eth_address
--
-- Description: A domain for validating Ethereum addresses.
-- Constraints: Must be a string of 42 characters, starting with '0x' and
--              containing 40 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_address AS VARCHAR(42) CHECK (VALUE ~ '^0x[a-f0-9]{40}$');

-------------------------------------------------------------------------------
-- Function: normalize_eth_address
-- Description: Normalizes the input Ethereum address to lowercase and
--              validates its format.
-- Parameters:
--   - address (TEXT): The Ethereum address to be normalized and validated.
-- Returns: The normalized address if valid, otherwise raises an exception.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.normalize_eth_address(address TEXT)
RETURNS types.eth_address
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN LOWER(address)::types.eth_address;
END;
$$;

-------------------------------------------------------------------------------
-- Domain: types.eth_block_hash
--
-- Description: A domain for validating Ethereum block hashes.
-- Constraints: Must be a string of 66 characters, starting with '0x' and
--              containing 64 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_block_hash AS VARCHAR(66) CHECK (VALUE ~ '^0x[a-f0-9]{64}$');

-------------------------------------------------------------------------------
-- Domain: types.eth_transaction_hash
--
-- Description: A domain for validating Ethereum transaction hashes.
-- Constraints: Must be a string of 66 characters, starting with '0x' and
--              containing 64 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_transaction_hash AS VARCHAR(66) CHECK (VALUE ~ '^0x[a-f0-9]{64}$');

-- migrate:down