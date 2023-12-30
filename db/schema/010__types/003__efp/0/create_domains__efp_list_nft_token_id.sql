-- migrate:up
-------------------------------------------------------------------------------
-- Domain: types.efp_list_nft_token_id
--
-- Description: EFP List NFT token ID.
-- Constraints: Value must be >= 0.
-------------------------------------------------------------------------------
CREATE DOMAIN types.efp_list_nft_token_id AS BIGINT NOT NULL CHECK (VALUE >= 0);



-- migrate:down
