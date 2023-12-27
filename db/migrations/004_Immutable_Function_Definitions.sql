-- migrate:up

-- Immutable Function Definitions



-------------------------------------------------------------------------------
-- Function: health
-- Description: Returns 'ok' if the database is healthy
-- Parameters: None
-- Returns: 'ok'
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.health()
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
   RETURN 'ok';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_uint8
-- Description: Validates that the given SMALLINT is [0, 255].
-- Parameters:
--   - value (SMALLINT): The value to be validated.
-- Returns: TRUE if the value is between 0 and 255, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_uint8(value SMALLINT)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN value >= 0 AND value <= 255;
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_hexstring
-- Description: Validates that the given string is a valid hexadecimal string.
--              The string must start with '0x' and contain an even number of
--              hexadecimal characters.
--              The function uses a regular expression to validate the format.
-- Parameters:
--   - hexstring (TEXT): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_hexstring(hexstring TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN hexstring ~ '^0x([a-f0-9]{2})+$';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_valid_address
-- Description: Validates that the given string is a valid Ethereum address.
--              The address must start with '0x' and contain 40 lowercase
--              hexadecimal characters.
--              The function uses a regular expression to validate the format.
-- Parameters:
--   - address (TEXT): The address to be validated.
-- Returns: TRUE if the address is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_valid_address(address TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN address ~ '^0x[a-f0-9]{40}$';
END;
$$;



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
-- Function: is_list_location_hexstring
-- Description: Validates that the given string is a valid list location
--              hexadecimal string. The string must start with '0x' and contain
--              168 hexadecimal characters. The function uses a regular
--              expression to validate the format.
-- Parameters:
--   - hexstring (TEXT): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_list_location_hexstring(hexstring TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN hexstring ~ '^0x[a-f0-9]{172}$';
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
--   - hexstring (TEXT): The hexadecimal string to be converted.
-- Returns: A bigint representation of the hexadecimal string or NULL if the
--          input is invalid or the result exceeds MAX_SAFE_INTEGER.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.convert_hex_to_bigint(hexstring TEXT)
RETURNS BIGINT
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    trimmed_hex TEXT;
    result BIGINT := 0;
    i INTEGER;
BEGIN
    -- Check if the hexstring is valid
    IF hexstring IS NULL OR NOT (hexstring ~ '^0x[a-f0-9]{64}$') THEN
        RETURN NULL;
    END IF;

    -- Remove '0x' prefix
    trimmed_hex := right(hexstring, 64);

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



-------------------------------------------------------------------------------
-- Function: decode_list_storage_location
-- Description: Decodes a list storage location string into its components.
--              The list storage location string is composed of:
--              - version (1 byte)
--              - locationType (1 byte)
--              - chainId (32 bytes)
--              - contractAddress (20 bytes)
--              - nonce (32 bytes)
--              The function validates the length of the input string and
--              extracts the components.
-- Parameters:
--   - list_storage_location (TEXT): The list storage location string to be
--                                   decoded.
-- Returns: A table with 'version' (SMALLINT), 'location_type' (SMALLINT),
--          'chain_id' (bigint), 'contract_address' (VARCHAR(42)), and 'nonce'
--          (VARCHAR(42)).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decode_list_storage_location(
  list_storage_location VARCHAR(174)
)
RETURNS TABLE(
  version SMALLINT,
  location_type SMALLINT,
  chain_id BIGINT,
  contract_address types.eth_address,
  nonce BIGINT
)
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    hex_data bytea;
    hex_chain_id VARCHAR(66);
    temp_nonce bytea;
BEGIN
    -- Check if the length is valid
    IF NOT public.is_list_location_hexstring(list_storage_location) THEN
        RAISE EXCEPTION 'Invalid list location';
    END IF;

    -- Convert the hex string (excluding '0x') to bytea
    hex_data := DECODE(SUBSTRING(list_storage_location FROM 3), 'hex');

    -- Extract version and locationType
    version := GET_BYTE(hex_data, 0);
    location_type := GET_BYTE(hex_data, 1);

    -- Validate version and locationType
    IF version != 1 OR location_type != 1 THEN
        RAISE EXCEPTION 'Invalid version or location type';
    END IF;

    -- Extract chainId (32 bytes) as hex string and convert to bigint
    hex_chain_id := '0x' || ENCODE(SUBSTRING(hex_data FROM 3 FOR 32), 'hex');
    chain_id := public.convert_hex_to_bigint(hex_chain_id);

    -- Extract contractAddress (20 bytes to TEXT)
    contract_address := ('0x' || ENCODE(SUBSTRING(hex_data FROM 35 FOR 20), 'hex'))::types.eth_address;

    -- Extract nonce (32 bytes to TEXT)
    temp_nonce := SUBSTRING(hex_data FROM 55 FOR 32);
    nonce := public.convert_hex_to_bigint('0x' || ENCODE(temp_nonce, 'hex'));

    RETURN NEXT;
END;
$$;



-- migrate:down