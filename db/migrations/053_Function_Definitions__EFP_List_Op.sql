-- migrate:up



-------------------------------------------------------------------------------
-- Function: validate_list_op__v001__opcode_001
-- Description: Validates the integrity of a list operation specific to version
--              1 and opcode 1.
-- Parameters:
--   - p_op_bytea (BYTEA): The operation data as a byte array.
-- Returns: void
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_list_op__v001__opcode_001(
    p_op_bytea BYTEA
)
RETURNS void
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF LENGTH(p_op_bytea) <> 24 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 opcode 1 (expected 24 bytes, got %)', LENGTH(p_op_bytea);
    END IF;
END;
$$;



-------------------------------------------------------------------------------
-- Function: validate_list_op__v001__opcode_002
-- Description: Validates the integrity of a list operation specific to version
--              1 and opcode 2.
-- Parameters:
--   - p_op_bytea (BYTEA): The operation data as a byte array.
-- Returns: void
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_list_op__v001__opcode_002(
    p_op_bytea BYTEA
)
RETURNS void
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF LENGTH(p_op_bytea) <> 24 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 opcode 2 (expected 24 bytes, got %)', LENGTH(p_op_bytea);
    END IF;
END;
$$;


-------------------------------------------------------------------------------
-- Function: validate_list_op__v001__opcode_003
-- Description: Validates the integrity of a list operation specific to version
--              1 and opcode 3.
-- Parameters:
--   - p_op_bytea (BYTEA): The operation data as a byte array.
-- Returns: void
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_list_op__v001__opcode_003(
    p_op_bytea BYTEA
)
RETURNS void
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF LENGTH(p_op_bytea) < 25 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 opcode 3 (expected at least 25 bytes, got %)', LENGTH(p_op_bytea);
    END IF;
END;
$$;


-------------------------------------------------------------------------------
-- Function: validate_list_op__v001__opcode_004
-- Description: Validates the integrity of a list operation specific to version
--              1 and opcode 4.
-- Parameters:
--   - p_op_bytea (BYTEA): The operation data as a byte array.
-- Returns: void
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_list_op__v001__opcode_004(
    p_op_bytea BYTEA
)
RETURNS void
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
    IF LENGTH(p_op_bytea) < 25 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 opcode 4 (expected at least 25 bytes, got %)', LENGTH(p_op_bytea);
    END IF;
END;
$$;



-------------------------------------------------------------------------------
-- Function: decode_list_op__v001
-- Description: This function validates and decodes a byte array representing a
--              version 1 list op.
-- Parameters:
--   - p_op_bytea (BYTEA): The operation data as a byte array.
-- Returns: types.efp_list_op__v001
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decode_list_op__v001(
  p_op_bytea BYTEA
)
RETURNS types.efp_list_op__v001
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    tmp_op_version INTEGER;
    op_version types.uint8__1;
    op_opcode types.uint8;
    op_data_hex types.hexstring;
BEGIN
    -- check if the length is valid
    IF LENGTH(p_op_bytea) < 2 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 (expected at least 2 bytes, got %)', LENGTH(p_op_bytea);
    END IF;

    ----------------------------------------
    -- version
    ----------------------------------------
    -- function should only be called if first byte is known to be version 1
    tmp_op_version := GET_BYTE(p_op_bytea, 0);
    -- validate it is version 1
    IF tmp_op_version != 1 THEN
        RAISE EXCEPTION 'Cannot decode list op with version=% using version 1 decoder', tmp_op_version;
    END IF;
    -- convert to types.uint8__1
    op_version := tmp_op_version::types.uint8__1;

    ----------------------------------------
    -- opcode
    ----------------------------------------
    op_opcode := GET_BYTE(p_op_bytea, 1)::types.uint8;
    -- cases:
    -- opcode 1 = add record [version, opcode, record]
    -- opcode 2 = remove record [version, opcode, record]
    -- opcode 3 = add tag [version, opcode, record, tag]
    -- opcode 4 = remove tag [version, opcode, record, tag]
    CASE
        WHEN op_opcode = 1 THEN
            PERFORM public.validate_list_op__v001__opcode_001(p_op_bytea);
        WHEN op_opcode = 2 THEN
            PERFORM public.validate_list_op__v001__opcode_002(p_op_bytea);
        WHEN op_opcode = 3 THEN
            PERFORM public.validate_list_op__v001__opcode_003(p_op_bytea);
        WHEN op_opcode = 4 THEN
            PERFORM public.validate_list_op__v001__opcode_004(p_op_bytea);
        ELSE
            RAISE EXCEPTION 'Cannot decode list op with opcode=% using version 1 decoder', op_opcode;
    END CASE;

    ----------------------------------------
    -- data
    ----------------------------------------
    op_data_hex := ('0x' || ENCODE(SUBSTRING(p_op_bytea FROM 3), 'hex'))::types.hexstring;

    -- Prepare return values
    RETURN (op_version, op_opcode, op_data_hex);
END;
$$;




-------------------------------------------------------------------------------
-- Function: decode_list_op
-- Description: Decodes a list operation string into its components.
--              The list operation string is composed of:
--              - version (1 byte)
--              - opcode (1 byte if version is 1)
--              - operation data (remaining bytes)
--              The function validates the length of the input string based on
--              version and opcode, and extracts the components.
-- Parameters:
--   - p_op (VARCHAR(255)): The operation data as a hex string.
-- Returns: A table with 'version' (SMALLINT), 'opcode' (SMALLINT or NULL),
--          and 'data' (types.hexstring or NULL).
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decode_list_op(
  p_op_hex VARCHAR(255)
)
RETURNS types.efp_list_op
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    op_bytea BYTEA;
    op_version types.uint8;
    op_opcode types.uint8;
    op_data_hex types.hexstring;
    op_v001 types.efp_list_op__v001;
BEGIN
    -- Check if the length is valid (at least 2 characters for '0x')
    IF NOT public.is_hexstring(p_op_hex) THEN
        RAISE EXCEPTION 'op is not a valid hexstring: "%"', p_op_hex;
    END IF;

    -- Convert the hex string (excluding '0x') to bytea
    op_bytea := DECODE(SUBSTRING(p_op_hex FROM 3), 'hex');

    -- could possibly just be the string "0x", in which case we can't get the
    -- version, so guard agains
    IF LENGTH(op_bytea) = 0 THEN
        RETURN (NULL, NULL, NULL);
    END IF;

    ----------------------------------------
    -- version
    ----------------------------------------
    op_version := GET_BYTE(op_bytea, 0)::types.uint8;

    -- Check version and determine opcode and data
    CASE
        WHEN op_version = 1 THEN
            op_v001 := public.decode_list_op__v001(op_bytea);
            op_opcode := op_v001.opcode;
            op_data_hex := op_v001.data_hex;
        ELSE
            -- no other versions are defined yet
            --
            -- technically both "opcode" and "data" are defined by the
            -- list op version 1 schema and so they may not exist in
            -- other versions, so we just return NULL for both
            op_opcode := NULL;
            op_data_hex := NULL;
    END CASE;

    RETURN (op_version, op_opcode, op_data_hex);
END;
$$;



-- migrate:down