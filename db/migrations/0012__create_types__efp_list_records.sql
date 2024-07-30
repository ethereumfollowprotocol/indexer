-- migrate:up
-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: An EFP list record
-------------------------------------------------------------------------------
CREATE TYPE
  types.efp_list_record AS (
    version types.uint8,
    record_type types.uint8,
    data types.bytea__not_null
  );



-------------------------------------------------------------------------------
-- Type: types.efp_list_record__v001
--
-- Description: An EFP list record with version byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE
  types.efp_list_record__v001 AS (
    version types.uint8__1,
    record_type types.uint8,
    data types.bytea__not_null
  );



-------------------------------------------------------------------------------
-- Type: types.efp_list_record__v001__record_type_001
--
-- Description: An EFP list record with version byte 0x01 and record_type byte
--              0x01
-------------------------------------------------------------------------------
CREATE TYPE
  types.efp_list_record__v001__record_type_001 AS (
    version types.uint8__1,
    record_type types.uint8__1,
    data types.bytea__not_null
  );



-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record with a tag
-------------------------------------------------------------------------------
CREATE TYPE
  types.efp_list_record_tag AS (
    version types.uint8,
    record_type types.uint8,
    data types.bytea__not_null,
    tag types.efp_tag
  );



-------------------------------------------------------------------------------
-- Function: validate_list_record__v001__record_type_001
-- Description: Validates the integrity of a list operation specific to version
--              1 and record_type 1.
-- Parameters:
--   - p_record_bytea (BYTEA): The operation data as a byte array.
-- Returns: void
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.validate_list_record__v001__record_type_001 (p_record_bytea BYTEA) RETURNS void LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF LENGTH(p_record_bytea) <> 22 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 record_type 1 (expected 22 bytes, got %)', LENGTH(p_record_bytea);
    END IF;
END;
$$;



-------------------------------------------------------------------------------
-- Function: decode__list_record__v001
-- Description: This function validates and decodes a byte array representing a
--              version 1 list op.
-- Parameters:
--   - p_record_bytea (BYTEA): The operation data as a byte array.
-- Returns: types.efp_list_record__v001
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.decode__list_record__v001 (p_record_bytea BYTEA) RETURNS types.efp_list_record__v001 LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    tmp_record_version INTEGER;
    record_version types.uint8__1 := 1;
    record_type types.uint8 := 0;
    record_data BYTEA;
BEGIN
    -- check if the length is valid
    IF LENGTH(p_record_bytea) < 2 THEN
        RAISE EXCEPTION 'validation failed for list record version 1 (expected at least 2 bytes, got %)', LENGTH(p_record_bytea);
    END IF;

    ----------------------------------------
    -- version
    ----------------------------------------
    -- function should only be called if first byte is known to be version 1
    tmp_record_version := GET_BYTE(p_record_bytea, 0);
    -- validate it is version 1
    IF tmp_record_version != 1 THEN
        RAISE EXCEPTION 'Cannot decode list record with version=% using version 1 decoder', tmp_record_version;
    END IF;
    -- convert to types.uint8__1
    record_version := tmp_record_version::types.uint8__1;

    ----------------------------------------
    -- record_type
    ----------------------------------------
    record_type := GET_BYTE(p_record_bytea, 1)::types.uint8;
    -- cases:
    -- record_type 1 = [version (1 byte), record_type (1 byte), address (20 bytes)]
    CASE
        WHEN record_type = 1 THEN
            PERFORM public.validate_list_record__v001__record_type_001(p_record_bytea);
        ELSE
            RAISE EXCEPTION 'Cannot decode list record with record_type=% using version 1 decoder', record_type;
    END CASE;

    ----------------------------------------
    -- data
    ----------------------------------------
    record_data := SUBSTRING(p_record_bytea FROM 3);

    -- Prepare return values
    RETURN (record_version, record_type, record_data::types.bytea__not_null);
END;
$$;



-------------------------------------------------------------------------------
-- Function: decode__list_record
-- Description: Decodes a list record string into its components.
--              The list record hex string is composed of:
--              - version (1 byte)
--              - record_type (1 byte if version is 1)
--              - operation data (remaining bytes)
--              The function validates the length of the input string based on
--              version and record_type, and extracts the components.
-- Parameters:
--   - p_record_hex (VARCHAR(255)): The operation data as a hex string.
-- Returns: types.efp_list_record
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.decode__list_record (p_record_hex VARCHAR(255)) RETURNS types.efp_list_record LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    record_bytea BYTEA;
    record_version types.uint8 := 0;
    record_type types.uint8 := 0;
    record_data BYTEA;
    record__v001 types.efp_list_record__v001;
BEGIN
    -- Check if the length is valid (at least 2 characters for '0x')
    IF NOT public.is_hexstring(p_record_hex) THEN
        RAISE EXCEPTION 'record is not a valid hexstring: "%"', p_record_hex;
    END IF;

    -- Convert the hex string (excluding '0x') to bytea
    record_bytea := DECODE(SUBSTRING(p_record_hex FROM 3), 'hex');

    -- could possibly just be the string "0x", in which case we can't get the
    -- version, so guard agains
    IF LENGTH(record_bytea) = 0 THEN
        RETURN (NULL, NULL, NULL);
    END IF;

    ----------------------------------------
    -- version
    ----------------------------------------
    record_version := GET_BYTE(record_bytea, 0)::types.uint8;

    CASE
        WHEN record_version = 1 THEN
            record__v001 := public.decode__list_record__v001(record_bytea);
            record_type := record__v001.record_type;
            record_data := record__v001.data;
        ELSE
            -- no other versions are defined yet
            --
            -- technically both "record_type" and "data" are defined by the
            -- list record version 1 schema and so they may not exist in
            -- other versions, so we just return NULL for both
            record_type := NULL;
            record_data := NULL;
    END CASE;

    RETURN (record_version, record_type, record_data::types.bytea__not_null);
END;
$$;



-------------------------------------------------------------------------------
-- Function: unpack__list_record_tag
-- Description: Unpacks a list record tag into its components.
-- Parameters:
--   - p_list_record_tag (BYTEA): The [record (N bytes), tag (M bytes)].
-- Returns: list_record (BYTEA), tag (types.efp_tag)
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.unpack__list_record_tag (p_list_record_tag types.bytea__not_null) RETURNS TABLE (
  list_record_bytea types.bytea__not_null,
  tag types.efp_tag
) LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    -- check the version byte exists and is 0x01
    IF LENGTH(p_list_record_tag) < 1 THEN
        RAISE EXCEPTION 'validation failed for list record tag (expected at least 1 byte, got %)',
            LENGTH(p_list_record_tag);
    END IF;
    IF GET_BYTE(p_list_record_tag, 0) != 1 THEN
        RAISE EXCEPTION 'validation failed for list record tag (expected version 1, got %)',
            GET_BYTE(p_list_record_tag, 0);
    END IF;

    -- check the record_type byte exists and is 0x01
    IF LENGTH(p_list_record_tag) < 2 THEN
        RAISE EXCEPTION 'validation failed for list record tag (expected at least 2 bytes, got %)',
            LENGTH(p_list_record_tag);
    END IF;
    IF GET_BYTE(p_list_record_tag, 1) != 1 THEN
        RAISE EXCEPTION 'validation failed for list record tag (expected record_type 1, got %)',
            GET_BYTE(p_list_record_tag, 1);
    END IF;

    -- record type 1 (address record) => record+tag length = (22 bytes) + (1+ byte)
    IF LENGTH(p_list_record_tag) < 23 THEN
        RAISE EXCEPTION 'validation failed for list record tag (expected at least 23 bytes, got %)',
            LENGTH(p_list_record_tag);
    END IF;

    list_record_bytea := SUBSTRING(p_list_record_tag FROM 1 FOR 22)::types.bytea__not_null;
    tag := convert_from(SUBSTRING(p_list_record_tag FROM 23), 'UTF-8')::types.efp_tag;

    RETURN NEXT;
END;
$$;



-- migrate:down