-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_accounts_with_primary_list
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW public.view__efp_accounts_with_primary_list AS
SELECT
  am.address,
  PUBLIC.convert_hex_to_bigint (am.value) AS primary_list_token_id
FROM
  PUBLIC.view__efp_account_metadata am
WHERE
  am.key = 'primary-list'
UNION
SELECT
  nft.efp_list_user AS address,
  MIN(nft.efp_list_nft_token_id) AS primary_list_token_id
FROM
  PUBLIC.view__efp_list_nfts_with_manager_user nft
WHERE
  NOT EXISTS (
    SELECT
      1
    FROM
      PUBLIC.view__efp_account_metadata am
    WHERE
      am.address = nft.efp_list_user
      AND am.key = 'primary-list'
  )
GROUP BY
  nft.efp_list_user;



-- migrate:down