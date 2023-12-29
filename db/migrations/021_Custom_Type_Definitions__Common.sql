-- migrate:up
-------------------------------------------------------------------------------
-- Domain: types.uint8
--
-- Description: Represents an 8-bit unsigned integer ranging from 0 to 255.
-- Constraints: Value must be within the range of 0 to 255 inclusive.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8 AS SMALLINT NOT NULL CHECK (
  VALUE >= 0
  AND VALUE <= 255
);



-------------------------------------------------------------------------------
-- Domain: types.uint8__1
--
-- Description: The value 1.
-- Constraints: Value must be 1.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__1 AS SMALLINT NOT NULL CHECK (VALUE = 1);



-------------------------------------------------------------------------------
-- Domain: types.uint8__2
--
-- Description: The value 2.
-- Constraints: Value must be 2.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__2 AS SMALLINT NOT NULL CHECK (VALUE = 2);



-------------------------------------------------------------------------------
-- Domain: types.uint8__3
--
-- Description: The value 3.
-- Constraints: Value must be 3.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__3 AS SMALLINT NOT NULL CHECK (VALUE = 3);



-------------------------------------------------------------------------------
-- Domain: types.uint8__4
--
-- Description: The value 4.
-- Constraints: Value must be 4.
-------------------------------------------------------------------------------
CREATE DOMAIN types.uint8__4 AS SMALLINT NOT NULL CHECK (VALUE = 4);



-------------------------------------------------------------------------------
-- Domain: bytea__not_null
-- Description: A BYTEA domain that is not nullable.
-------------------------------------------------------------------------------
CREATE DOMAIN types.bytea__not_null AS BYTEA NOT NULL;



-------------------------------------------------------------------------------
-- Domain: types.hexstring
--
-- Description: Represents a hexadecimal string.
-- Constraints: Must conform to the format specified in the is_hexstring
--              function, typically starting with '0x'. Minimum length is 2.
-------------------------------------------------------------------------------
CREATE DOMAIN types.hexstring AS VARCHAR(255) CHECK (VALUE ~ '^0x([a-f0-9]{2})*$');



-------------------------------------------------------------------------------
-- Function: public.hexlify
-- Description: Converts a BYTEA input to a hexadecimal string.
-- Parameters:
--   - bytea_data (BYTEA): The binary data to be converted.
-- Returns: The hexadecimal string representation of the input binary data.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.hexlify (bytea_data BYTEA) RETURNS types.hexstring LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    -- Convert BYTEA to a hexadecimal string with '0x' prefix
    RETURN ('0x' || ENCODE(bytea_data, 'hex'))::types.hexstring;
END;
$$;



-------------------------------------------------------------------------------
-- Function: public.unhexlify
-- Description: Converts a hexadecimal string to BYTEA.
-- Parameters:
--   - hexstring_data (types.hexstring): The hexadecimal string to be converted.
-- Returns: The BYTEA representation of the input hexadecimal string.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.unhexlify (hexstring_data types.hexstring) RETURNS BYTEA LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    -- Convert hexadecimal string (without '0x' prefix) to BYTEA
    RETURN DECODE(SUBSTRING(hexstring_data FROM 3), 'hex');
END;
$$;



-- migrate:down
