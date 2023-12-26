-- migrate:up
-- Create domains
-------------------------------------------------------------------------------
-- Domain: uint8
--
-- Description: Represents an 8-bit unsigned integer ranging from 0 to 255.
-- Constraints: Value must be within the range of 0 to 255 inclusive.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8 AS SMALLINT CHECK (
  VALUE >= 0
  AND VALUE <= 255
);

-------------------------------------------------------------------------------
-- Domain: hexstring
--
-- Description: Represents a hexadecimal string.
-- Constraints: Must conform to the format specified in the is_hexstring
--              function, typically starting with '0x'.
-------------------------------------------------------------------------------
CREATE DOMAIN types.hexstring AS VARCHAR(255) CHECK (VALUE ~ '^0x([a-f0-9]{2})+$');

-------------------------------------------------------------------------------
-- Domain: eth_address
--
-- Description: A domain for validating Ethereum addresses.
-- Constraints: Must be a string of 42 characters, starting with '0x' and
--              containing 40 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_address AS VARCHAR(42) CHECK (VALUE ~ '^0x[a-f0-9]{40}$');



-------------------------------------------------------------------------------
-- Domain: eth_block_hash
--
-- Description: A domain for validating Ethereum block hashes.
-- Constraints: Must be a string of 66 characters, starting with '0x' and
--              containing 64 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_block_hash AS VARCHAR(66) CHECK (VALUE ~ '^0x[a-f0-9]{64}$');



-------------------------------------------------------------------------------
-- Domain: eth_transaction_hash
--
-- Description: A domain for validating Ethereum transaction hashes.
-- Constraints: Must be a string of 66 characters, starting with '0x' and
--              containing 64 lowercase hexadecimal characters.
-------------------------------------------------------------------------------
CREATE DOMAIN types.eth_transaction_hash AS VARCHAR(66) CHECK (VALUE ~ '^0x[a-f0-9]{64}$');

-- migrate:down