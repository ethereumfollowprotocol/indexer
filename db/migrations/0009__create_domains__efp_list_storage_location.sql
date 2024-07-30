-- migrate:up
-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location_slot
--
-- Description: EFP List Storage Location Slot.
-- Constraints: Value must be 32-byte array.
-------------------------------------------------------------------------------
CREATE DOMAIN
  types.efp_list_storage_location_slot AS BYTEA CHECK (octet_length(VALUE) = 32);



-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location__v001__location_type_001
--
-- Description: A list storage location with version byte 0x01 and location
--              type byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE
  types.efp_list_storage_location__v001__location_type_001 AS (
    VERSION types.uint8__1,
    location_type types.uint8__1,
    chain_id BIGINT,
    contract_address types.eth_address,
    slot types.efp_list_storage_location_slot
  );



-------------------------------------------------------------------------------
-- Function: is_list_storage_location_hexstring
-- Description: Validates that the given string is a valid list location
--              hexadecimal string. The string must start with '0x' and contain
--              172 hexadecimal characters. The function uses a regular
--              expression to validate the format.
-- Parameters:
--   - hexstring (TEXT): The hexadecimal string to be validated.
-- Returns: TRUE if the string is valid, FALSE otherwise.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.is_list_storage_location_hexstring (hexstring TEXT) RETURNS BOOLEAN LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    RETURN hexstring ~ '^0x[a-f0-9]{172}$';
END;
$$;



-------------------------------------------------------------------------------
-- Function: public.decode__efp_list_storage_location__v001__location_type_001
-- Description: Decodes a list storage location string into its components.
--              The list storage location string is composed of:
--              - version (1 byte)
--              - locationType (1 byte)
--              - chainId (32 bytes)
--              - contractAddress (20 bytes)
--              - slot (32 bytes)
--              The function validates the length of the input string and
--              extracts the components.
-- Parameters:
--   - p_list_storage_location_hex (TEXT): The list storage location string to
--                                         be decoded.
-- Returns: types.efp_list_storage_location__v001__location_type_001
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION public.decode__efp_list_storage_location__v001__location_type_001 (p_list_storage_location_hex VARCHAR(174)) RETURNS types.efp_list_storage_location__v001__location_type_001 LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    hex_data bytea;
    hex_chain_id VARCHAR(66);
    version types.uint8 := 0;
    location_type types.uint8 := 0;
    chain_id BIGINT;
    contract_address types.eth_address;
    slot types.efp_list_storage_location_slot;
BEGIN
    -- Check if the length is valid
    IF NOT public.is_list_storage_location_hexstring(p_list_storage_location_hex) THEN
        RAISE EXCEPTION 'Invalid list location';
    END IF;

    -- Convert the hex string (excluding '0x') to bytea
    hex_data := DECODE(SUBSTRING(p_list_storage_location_hex FROM 3), 'hex');

    ----------------------------------------
    -- version
    ----------------------------------------
    version := GET_BYTE(hex_data, 0)::types.uint8;
    IF version != 1 THEN
        RAISE EXCEPTION 'Invalid version: % (expected 1)', version;
    END IF;

    ----------------------------------------
    -- location_type
    ----------------------------------------
    location_type := GET_BYTE(hex_data, 1)::types.uint8;
    IF location_type != 1 THEN
        RAISE EXCEPTION 'Invalid location type: % (expected 1)', location_type;
    END IF;

    ----------------------------------------
    -- chain_id
    ----------------------------------------

    -- Extract chainId (32 bytes) as hex string and convert to bigint
    hex_chain_id := '0x' || ENCODE(SUBSTRING(hex_data FROM 3 FOR 32), 'hex');
    chain_id := public.convert_hex_to_bigint(hex_chain_id);

    ----------------------------------------
    -- contract_address
    ----------------------------------------

    -- Extract contractAddress (20 bytes to TEXT)
    contract_address := ('0x' || ENCODE(SUBSTRING(hex_data FROM 35 FOR 20), 'hex'))::types.eth_address;

    ----------------------------------------
    -- slot
    ----------------------------------------

    -- Extract slot (32 bytes)
    slot := SUBSTRING(hex_data FROM 55 FOR 32)::types.efp_list_storage_location_slot;

    -- Return the decoded list storage location
    RETURN (
        version::types.uint8__1,
        location_type::types.uint8__1,
        chain_id,
        contract_address,
        slot
      );
END;
$$;



-- migrate:down