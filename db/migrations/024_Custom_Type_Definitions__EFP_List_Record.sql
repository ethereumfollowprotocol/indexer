-- migrate:up

-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record AS (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring
);

-------------------------------------------------------------------------------
-- Domain: types.efp_tag
--
-- Description: A tag for a list record
-- Constraints: Must be a string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN types.efp_tag AS VARCHAR(255);

-------------------------------------------------------------------------------
-- Type: types.efp_list_record
--
-- Description: A list record with a tag
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_record_tag AS (
  version types.uint8,
  record_type types.uint8,
  data types.hexstring,
  tag types.efp_tag
);

-- migrate:down