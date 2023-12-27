-- migrate:up
-------------------------------------------------------------------------------
-- Type: types.efp_list_op
--
-- Description: A list op
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op AS (version TYPES.uint8, op TYPES.hexstring);

-- ============================================================================
-- version 1
-- ============================================================================
--
--
--
-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001
--
-- Description: A list op with version byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op__v001 AS (
  version TYPES.uint8__1,
  opcode TYPES.uint8,
  data TYPES.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_001
--
-- Description: A list op with version byte 0x01 and opcode byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op__v001__opcode_001 AS (
  version TYPES.uint8__1,
  -- opcode 0x01: add record
  opcode TYPES.uint8__1,
  -- remove record operation => data is [record]
  record TYPES.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_002
--
-- Description: A list op with version byte 0x01 and opcode byte 0x02
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op__v001__opcode_002 AS (
  version TYPES.uint8__1,
  -- opcode 0x02: remove record
  opcode TYPES.uint8__2,
  -- remove record operation => data is [record]
  record TYPES.hexstring
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_003
--
-- Description: A list op with version byte 0x01 and opcode byte 0x03
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op__v001__opcode_003 AS (
  version TYPES.uint8__1,
  -- opcode 0x03: add record tag
  opcode TYPES.uint8__3,
  -- add record operation => data is [record, tag]
  record TYPES.hexstring,
  tag TYPES.efp_tag
);

-------------------------------------------------------------------------------
-- Type: types.efp_list_op__v001__opcode_004
--
-- Description: A list op with version byte 0x01 and opcode byte 0x04
-------------------------------------------------------------------------------
CREATE TYPE TYPES.efp_list_op__v001__opcode_004 AS (
  version TYPES.uint8__1,
  -- opcode 0x04: remove record tag
  opcode TYPES.uint8__4,
  -- remove record operation => data is [record, tag]
  record TYPES.hexstring,
  tag TYPES.efp_tag
);

-- migrate:down