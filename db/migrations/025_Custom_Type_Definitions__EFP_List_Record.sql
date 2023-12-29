-- migrate:up
-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: An EFP list record
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record AS (
  version types.uint8,
  record_type types.uint8,
  data types.bytea__not_null
);



-------------------------------------------------------------------------------
-- Type: types.efp_list_record__v001
--
-- Description: An EFP list record with version byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record__v001 AS (
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
CREATE TYPE types.efp_list_record__v001__record_type_001 AS (
  version types.uint8__1,
  record_type types.uint8__1,
  data types.bytea__not_null
);



-------------------------------------------------------------------------------
-- Domain: types.efp_tag
--
-- Description: A tag for a list record
-- Constraints: Must be a non-empty string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN types.efp_tag AS VARCHAR(255) NOT NULL CHECK (LENGTH(VALUE) > 0);



-------------------------------------------------------------------------------
-- Domain: types.efp_tag_nullable
--
-- Description: A tag for a list record, or NULL.
-- Constraints: Must be a non-empty string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN types.efp_tag__nullable AS VARCHAR(255);



-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record with a tag
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record_tag AS (
  version types.uint8,
  record_type types.uint8,
  data types.bytea__not_null,
  tag types.efp_tag
);



-- migrate:down
