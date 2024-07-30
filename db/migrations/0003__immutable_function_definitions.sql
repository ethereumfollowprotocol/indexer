-- migrate:up
-- Immutable Function Definitions
-------------------------------------------------------------------------------
-- Function: health
-- Description: Returns 'ok' if the database is healthy
-- Parameters: None
-- Returns: 'ok'
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.health () RETURNS TEXT LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
   RETURN 'ok';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_uint8
-- Description: Validates that the given SMALLINT is [0, 255].
-- Parameters:
--   - p_value (SMALLINT): The value to be validated.
-- Returns: TRUE if the value is between 0 and 255, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.is_uint8 (p_value SMALLINT) RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN p_value >= 0 AND p_value <= 255;
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_hexstring
-- Description: Validates that the given string is a valid hexadecimal string.
--              The string must start with '0x' and contain an even number of
--              hexadecimal characters.
--              The function uses a regular expression to validate the format.
-- Parameters:
--   - p_hexstring (TEXT): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.is_hexstring (p_hexstring TEXT) RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN p_hexstring ~ '^0x([a-f0-9]{2})*$';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_valid_address
-- Description: Validates that the given string is a valid Ethereum address.
--              The address must start with '0x' and contain 40 lowercase
--              hexadecimal characters.
--              The function uses a regular expression to validate the format.
-- Parameters:
--   - p_address (TEXT): The address to be validated.
-- Returns: TRUE if the address is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.is_valid_address (p_address TEXT) RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN p_address ~ '^0x[a-f0-9]{40}$';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_valid_address
-- Description: Validates that the given byte array is a valid Ethereum
--              address by checking that it is 20 bytes long.
-- Parameters:
--   - p_address_bytea (BYTEA): The byte array to be validated.
-- Returns: TRUE if the address is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.is_valid_address (p_address_bytea BYTEA) RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN LENGTH(p_address_bytea) = 20;
END;
$$;



-------------------------------------------------------------------------------
-- Function: convert_hex_to_bigint
-- Description: Converts a 66-character hexadecimal string to a bigint. The
--              hex string should start with '0x' and contain 64 hexadecimal
--              digits. The function validates the string format and ensures
--              the resulting bigint does not exceed JavaScript's
--              MAX_SAFE_INTEGER.
-- Parameters:
--   - p_hexstring (TEXT): The hexadecimal string to be converted.
-- Returns: A bigint representation of the hexadecimal string or NULL if the
--          input is invalid or the result exceeds MAX_SAFE_INTEGER.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.convert_hex_to_bigint (p_hexstring TEXT) RETURNS BIGINT LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    trimmed_hex TEXT;
    result BIGINT := 0;
    i INTEGER;
BEGIN
    -- Check if the p_hexstring is valid
    IF p_hexstring IS NULL OR NOT (p_hexstring ~ '^0x[a-f0-9]{64}$') THEN
        RETURN NULL;
    END IF;

    -- Remove '0x' prefix
    trimmed_hex := right(p_hexstring, 64);

    -- Convert hex string to bigint
    FOR i IN 1..64 LOOP
        result := result * 16 +
                  ('x' || substr(trimmed_hex, i, 1))::bit(4)::bigint;
    END LOOP;

    -- Check if result exceeds MAX_SAFE_INTEGER in JavaScript
    IF result > 9007199254740991 THEN
        RETURN NULL;
    END IF;

    RETURN result;
END;
$$;



-- migrate:down
