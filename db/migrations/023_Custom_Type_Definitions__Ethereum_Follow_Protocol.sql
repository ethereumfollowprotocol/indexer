-- migrate:up
-- Custom Type Definitions


    -- TODO: model as data
    --       handle version_001 and version_001__location_type_001 separately
    -- data types.hexstring

-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location__version_001__location_type_001
--
-- Description: A list storage location
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_storage_location__version_001__location_type_001 as (
    version types.uint8__1,
    location_type types.uint8__1,
    chain_id BIGINT,
    contract_address types.eth_address,
    nonce BIGINT
);



-------------------------------------------------------------------------------
-- Type: types.efp_list_op
--
-- Description: A list op
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_op AS (
  version types.uint8,
  opcode types.uint8,
  data types.hexstring
);

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