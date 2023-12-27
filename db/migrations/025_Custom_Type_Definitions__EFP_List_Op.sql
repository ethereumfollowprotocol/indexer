-- migrate:up
-------------------------------------------------------------------------------
-- Type: types.efp_list_op
--
-- Description: An EFP list op
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op AS (
    version types.uint8,
    opcode types.uint8,
    data_hex types.hexstring
);

-- ============================================================================
-- version 1
-- ============================================================================
--
--
--
-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001
--
-- Description: An EFP list op with version byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op__v001 AS (
    version types.uint8__1,
    opcode types.uint8,
    data_hex types.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_001
--
-- Description: An EFP list op with version byte 0x01 and opcode byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op__v001__opcode_001 AS (
    version types.uint8__1,
    -- opcode 0x01: add record
    opcode types.uint8__1,
    -- remove record operation => data is [record]
    record_hex types.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_002
--
-- Description: An EFP list op with version byte 0x01 and opcode byte 0x02
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op__v001__opcode_002 AS (
    version types.uint8__1,
    -- opcode 0x02: remove record
    opcode types.uint8__2,
    -- remove record operation => data is [record]
    record_hex types.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_003
--
-- Description: An EFP list op with version byte 0x01 and opcode byte 0x03
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op__v001__opcode_003 AS (
    version types.uint8__1,
    -- opcode 0x03: add record tag
    opcode types.uint8__3,
    -- add record operation => data is [record, tag]
    record_hex types.hexstring,
    tag types.efp_tag
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_004
--
-- Description: An EFP list op with version byte 0x01 and opcode byte 0x04
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op__v001__opcode_004 AS (
    version types.uint8__1,
    -- opcode 0x04: remove record tag
    opcode types.uint8__4,
    -- remove record operation => data is [record, tag]
    record_hex types.hexstring,
    tag types.efp_tag
);

-- migrate:down