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
-- Domain: types.uint8__1
--
-- Description: The value 1.
-- Constraints: Value must be 1.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__1 AS SMALLINT CHECK (VALUE = 1);

-------------------------------------------------------------------------------
-- Domain: types.uint8__2
--
-- Description: The value 2.
-- Constraints: Value must be 2.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__2 AS SMALLINT CHECK (VALUE = 2);


-------------------------------------------------------------------------------
-- Domain: types.uint8__3
--
-- Description: The value 3.
-- Constraints: Value must be 3.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__3 AS SMALLINT CHECK (VALUE = 3);


-------------------------------------------------------------------------------
-- Domain: types.uint8__4
--
-- Description: The value 4.
-- Constraints: Value must be 4.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__4 AS SMALLINT CHECK (VALUE = 4);


-------------------------------------------------------------------------------
-- Domain: types.hexstring
--
-- Description: Represents a hexadecimal string.
-- Constraints: Must conform to the format specified in the is_hexstring
--              function, typically starting with '0x'. Minimum length is 2.
-------------------------------------------------------------------------------
CREATE DOMAIN types.hexstring AS VARCHAR(255) CHECK (VALUE ~ '^0x([a-f0-9]{2})*$');

-- migrate:down