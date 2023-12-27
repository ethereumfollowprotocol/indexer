-- migrate:up

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

-- migrate:down