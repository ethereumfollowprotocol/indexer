-- migrate:up
-------------------------------------------------------------------------------
-- View: view__events__efp_accounts_with_primary_list
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW public.view__events__efp_accounts_with_primary_list AS
SELECT
  am.address,
  PUBLIC.convert_hex_to_bigint (am.value) AS primary_list_token_id
FROM
  PUBLIC.efp_account_metadata am
WHERE
  am.key = 'primary-list'
UNION
SELECT
  l.user AS address,
  MIN(l.token_id) AS primary_list_token_id
FROM
  PUBLIC.efp_lists l
WHERE
  NOT EXISTS (
    SELECT
      1
    FROM
      PUBLIC.efp_account_metadata am
    WHERE
      am.address = l.user
      AND am.key = 'primary-list'
  )
GROUP BY
  l.user;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__events__efp_accounts_with_primary_list
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS public.view__events__efp_accounts_with_primary_list CASCADE;