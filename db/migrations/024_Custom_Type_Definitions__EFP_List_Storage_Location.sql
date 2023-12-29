-- migrate:up
-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location_nonce
--
-- Description: EFP List Storage Location Nonce.
-- Constraints: Value must be >= 0.
-------------------------------------------------------------------------------
-- TODO: de-couple to it's own table and make NOT NULL
CREATE DOMAIN types.efp_list_storage_location_nonce AS BIGINT CHECK (VALUE >= 0);



-------------------------------------------------------------------------------
-- Domain: types.efp_list_storage_location__v001__location_type_001
--
-- Description: A list storage location with version byte 0x01 and location
--              type byte 0x01
-------------------------------------------------------------------------------
CREATE TYPE types.efp_list_storage_location__v001__location_type_001 AS (
  VERSION types.uint8__1,
  location_type types.uint8__1,
  chain_id BIGINT,
  contract_address types.eth_address,
  nonce types.efp_list_storage_location_nonce
);



-- migrate:down
