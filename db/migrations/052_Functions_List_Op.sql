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
-- Returns: A table with 'version' (SMALLINT), 'opcode' (SMALLINT), and
--          'data' (types.hexstring). The data is returned as a hex string.
-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.decode_list_op__v001(
  p_op_bytea BYTEA
)
RETURNS TABLE(
    version SMALLINT,
    opcode SMALLINT,
    data types.hexstring
)
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    op_version SMALLINT;
    op_opcode SMALLINT;
    op_data_hexstring types.hexstring;
BEGIN
    -- check if the length is valid
    IF LENGTH(p_op_bytea) < 2 THEN
        RAISE EXCEPTION 'validation failed for list op version 1 (expected at least 2 bytes, got %)', LENGTH(p_op_bytea);
    END IF;

    ----------------------------------------
    -- version
    ----------------------------------------
    op_version := GET_BYTE(p_op_bytea, 0)::SMALLINT;
    -- validate it is version 1
    IF op_version != 1 THEN
        RAISE EXCEPTION 'Cannot decode list op with version=% using version 1 decoder', op_version;
    END IF;

    ----------------------------------------
    -- opcode
    ----------------------------------------
    op_opcode := GET_BYTE(p_op_bytea, 1)::SMALLINT;
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
    op_data_hexstring := ('0x' || ENCODE(SUBSTRING(p_op_bytea FROM 3), 'hex'))::types.hexstring;

    -- Prepare return values
    version := op_version;
    opcode := op_opcode;
    data := op_data_hexstring;

    RETURN NEXT;
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
  p_op VARCHAR(255)
)
RETURNS TABLE(
  version SMALLINT,
  opcode SMALLINT,
  data types.hexstring
)
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
    op_bytea BYTEA;
    op_version SMALLINT;
    op_opcode SMALLINT;
    op_data_hexstring types.hexstring;
    op_record_version_1 RECORD;
BEGIN
    -- Check if the length is valid (at least 2 characters for '0x')
    IF NOT public.is_hexstring(p_op) THEN
        RAISE EXCEPTION 'op is not a valid hexstring: "%"', p_op;
    END IF;

    -- default to NULL because may be just "0x" with no version/opcode/data
    -- if user uploads "0x" as a list op (it will not revert)
    op_version := NULL;
    op_opcode := NULL;
    op_data_hexstring := NULL;

    -- Convert the hex string (excluding '0x') to bytea
    op_bytea := DECODE(SUBSTRING(p_op FROM 3), 'hex');

    -- could possibly just be the string "0x", in which case we can't get the
    -- version, so guard agains
    IF LENGTH(op_bytea) > 0 THEN

      ----------------------------------------
      -- version
      ----------------------------------------
      op_version := GET_BYTE(op_bytea, 0)::SMALLINT;

      -- Check version and determine opcode and data
      CASE
          WHEN op_version = 1 THEN
              op_record_version_1 := public.decode_list_op__v001(op_bytea);
              op_opcode := op_record_version_1.opcode;
              op_data_hexstring := op_record_version_1.data;
          ELSE
              -- no other versions are defined yet
              -- do nothing
              -- NULL;
      END CASE;
    END IF;

    -- Prepare return values
    version := op_version;
    opcode := op_opcode;
    data := op_data_hexstring;

    RETURN NEXT;
END;
$$;



-- migrate:down