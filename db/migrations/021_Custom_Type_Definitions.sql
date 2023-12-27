-- migrate:up
-- Custom Type Definitions

-------------------------------------------------------------------------------
-- Domain: types.uint8
--
-- Description: Represents an 8-bit unsigned integer ranging from 0 to 255.
-- Constraints: Value must be within the range of 0 to 255 inclusive.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8 AS SMALLINT CHECK (
  VALUE >= 0
  AND VALUE <= 255
);

-------------------------------------------------------------------------------
-- Domain: types.hexstring
--
-- Description: Represents a hexadecimal string.
-- Constraints: Must conform to the format specified in the is_hexstring
--              function, typically starting with '0x'. Minimum length is 2.
-------------------------------------------------------------------------------
CREATE DOMAIN types.hexstring AS VARCHAR(255) CHECK (VALUE ~ '^0x([a-f0-9]{2})*$');

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


-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location
--
-- Description: A list storage location
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_storage_location as (
    version types.uint8,
    location_type types.uint8,
    data types.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op
--
-- Description: A list op
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op AS (
  version types.uint8,
  opcode types.uint8,
  data types.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record AS (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring
);

-------------------------------------------------------------------------------
-- Domain: types.efp_tag
--
-- Description: A tag for a list record
-- Constraints: Must be a string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN types.efp_tag AS VARCHAR(255);

-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record with a tag
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record_tag AS (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring,
  tag types.efp_tag
);

-- migrate:down