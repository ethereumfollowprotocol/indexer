-- migrate:up

-- Function Definitions

-------------------------------------------------------------------------------
-- Function: generate_ulid
-- Description: Generates a ULID (Universally Unique Lexicographically Sortable
--              Identifier).
-- Parameters: None
-- Returns: A ULID as a text string.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_ulid()
RETURNS text
LANGUAGE plpgsql VOLATILE
AS $$
DECLARE
  -- Crockford's Base32
  encoding   BYTEA = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  timestamp  BYTEA = E'\\000\\000\\000\\000\\000\\000';
  output     TEXT = '';

  unix_time  BIGINT;
  ulid       BYTEA;
BEGIN
  -- 6 timestamp bytes
  unix_time = (EXTRACT(EPOCH FROM CLOCK_TIMESTAMP()) * 1000)::BIGINT;
  timestamp = SET_BYTE(timestamp, 0, (unix_time >> 40)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 1, (unix_time >> 32)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 2, (unix_time >> 24)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 3, (unix_time >> 16)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 4, (unix_time >> 8)::BIT(8)::INTEGER);
  timestamp = SET_BYTE(timestamp, 5, unix_time::BIT(8)::INTEGER);

  -- 10 entropy bytes
  ulid = timestamp || gen_random_bytes(10);

  -- Encode the timestamp
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 0) & 224) >> 5));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 0) & 31)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 1) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 1) & 7) << 2) | ((GET_BYTE(ulid, 2) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 2) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 2) & 1) << 4) | ((GET_BYTE(ulid, 3) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 3) & 15) << 1) | ((GET_BYTE(ulid, 4) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 4) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 4) & 3) << 3) | ((GET_BYTE(ulid, 5) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 5) & 31)));

  -- Encode the entropy
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 6) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 6) & 7) << 2) | ((GET_BYTE(ulid, 7) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 7) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 7) & 1) << 4) | ((GET_BYTE(ulid, 8) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 8) & 15) << 1) | ((GET_BYTE(ulid, 9) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 9) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 9) & 3) << 3) | ((GET_BYTE(ulid, 10) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 10) & 31)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 11) & 248) >> 3));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 11) & 7) << 2) | ((GET_BYTE(ulid, 12) & 192) >> 6)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 12) & 62) >> 1));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 12) & 1) << 4) | ((GET_BYTE(ulid, 13) & 240) >> 4)));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 13) & 15) << 1) | ((GET_BYTE(ulid, 14) & 128) >> 7)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 14) & 124) >> 2));
  output = output || CHR(GET_BYTE(encoding, ((GET_BYTE(ulid, 14) & 3) << 3) | ((GET_BYTE(ulid, 15) & 224) >> 5)));
  output = output || CHR(GET_BYTE(encoding, (GET_BYTE(ulid, 15) & 31)));

  RETURN output;
END
$$;



-------------------------------------------------------------------------------
-- Function: health
-- Description: Returns 'ok' if the database is healthy
-- Parameters: None
-- Returns: 'ok'
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.health()
RETURNS text
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
   RETURN 'ok';
END;
$$;



-------------------------------------------------------------------------------
-- Function: update_updated_at_column
-- Description: Updates the 'updated_at' column of a table to the current
--              timestamp.
-- Parameters: None
-- Returns: The updated row.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql VOLATILE
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;



-------------------------------------------------------------------------------
-- Function: convert_hex_to_bigint
-- Description: Converts a 66-character hexadecimal string to a bigint. The
--              hex string should start with '0x' and contain 64 hexadecimal
--              digits. The function validates the string format and ensures
--              the resulting bigint does not exceed JavaScript's MAX_SAFE_INTEGER.
-- Parameters:
--   - hexstring (text): The hexadecimal string to be converted.
-- Returns: A bigint representation of the hexadecimal string or NULL if the
--          input is invalid or the result exceeds MAX_SAFE_INTEGER.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.convert_hex_to_bigint(hexstring text)
RETURNS bigint
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    trimmed_hex text;
    result bigint := 0;
    i integer;
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
-- Function: is_uint8
-- Description: Validates that the given smallint is [0, 255].
-- Parameters:
--   - value (smallint): The value to be validated.
-- Returns: TRUE if the value is between 0 and 255, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_uint8(value smallint)
RETURNS boolean
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
--   - hexstring (text): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_hexstring(hexstring text)
RETURNS boolean
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
--   - address (text): The address to be validated.
-- Returns: TRUE if the address is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_valid_address(address text)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN address ~ '^0x[a-f0-9]{40}$';
END;
$$;



-------------------------------------------------------------------------------
-- Function: is_list_location_hexstring
-- Description: Validates that the given string is a valid list location
--              hexadecimal string. The string must start with '0x' and contain
--              168 hexadecimal characters. The function uses a regular
--              expression to validate the format.
-- Parameters:
--   - hexstring (text): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_list_location_hexstring(hexstring text)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    RETURN hexstring ~ '^0x[a-f0-9]{172}$';
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
--   - list_storage_location (text): The list storage location string to be
--                                   decoded.
-- Returns: A table with 'version' (smallint), 'location_type' (smallint),
--          'chain_id' (bigint), 'contract_address' (varchar(42)), and 'nonce'
--          (varchar(42)).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decode_list_storage_location(list_storage_location character varying(174))
RETURNS TABLE(version smallint, location_type smallint, chain_id bigint, contract_address character varying(42), nonce bigint)
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    hex_data bytea;
    hex_chain_id character varying(66);
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

    -- Extract contractAddress (20 bytes to text)
    contract_address := '0x' || ENCODE(SUBSTRING(hex_data FROM 35 FOR 20), 'hex');

    -- Extract nonce (32 bytes to text)
    temp_nonce := SUBSTRING(hex_data FROM 55 FOR 32);
    nonce := public.convert_hex_to_bigint('0x' || ENCODE(temp_nonce, 'hex'));

    RETURN NEXT;
END;
$$;



-- migrate:down