-- migrate:up
-- Custom Type Definitions
-------------------------------------------------------------------------------
-- Domain: types.eth_chain_id
--
-- Description: Ethereum chain ID.
-- Constraints: Value must be >= 0.
-------------------------------------------------------------------------------
-- TODO: de-couple to it's own table and make NOT NULL
CREATE DOMAIN types.eth_chain_id AS BIGINT NOT NULL CHECK (VALUE >= 0);



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
CREATE
OR REPLACE FUNCTION public.normalize_eth_address (address TEXT) RETURNS types.eth_address LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF address IS NULL THEN
        RAISE EXCEPTION 'address cannot be NULL';
    END IF;
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
CREATE DOMAIN types.eth_block_hash AS VARCHAR(66) NOT NULL CHECK (VALUE ~ '^0x[a-f0-9]{64}$');



-------------------------------------------------------------------------------
-- Function: normalize_eth_block_hash
-- Description: Normalizes the provided mixed-case Ethereum block hash to
--              lowercase and validates its format.
-- Parameters:
--   - block_hash (TEXT): The block hash to be normalized and validated.
-- Returns: The normalized block hash if valid, otherwise raises an exception.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.normalize_eth_block_hash (block_hash text) RETURNS types.eth_block_hash LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF block_hash IS NULL THEN
        RAISE EXCEPTION 'block_hash cannot be NULL';
    END IF;
    RETURN LOWER(block_hash)::types.eth_block_hash;
END;
$$;



-------------------------------------------------------------------------------
-- Domain: types.eth_transaction_hash
--
-- Description: A domain for validating Ethereum transaction hashes.
-- Constraints: Must be a string of 66 characters, starting with '0x' and
--              containing 64 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_transaction_hash AS VARCHAR(66) NOT NULL CHECK (VALUE ~ '^0x[a-f0-9]{64}$');



-------------------------------------------------------------------------------
-- Function: normalize_eth_transaction_hash
-- Description: Normalizes the provided mixed-case Ethereum transaction hash to
--              lowercase and validates its format.
-- Parameters:
--   - transaction_hash (TEXT): The transaction hash to be normalized and
--                              validated.
-- Returns: The normalized transaction hash if valid, otherwise raises an
--          exception.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.normalize_eth_transaction_hash (transaction_hash text) RETURNS types.eth_transaction_hash LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF transaction_hash IS NULL THEN
        RAISE EXCEPTION 'transaction_hash cannot be NULL';
    END IF;
    RETURN LOWER(transaction_hash)::types.eth_transaction_hash;
END;
$$;



CREATE
OR REPLACE FUNCTION public.sort_key (
  p_block_number BIGINT,
  p_transaction_index NUMERIC,
  p_log_index NUMERIC
) RETURNS TEXT AS $$
BEGIN
    RETURN
        LPAD(p_block_number::TEXT, 12, '0') || '-' ||
        LPAD(p_transaction_index::TEXT, 6, '0') || '-' ||
        LPAD(p_log_index::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;



-- migrate:down
