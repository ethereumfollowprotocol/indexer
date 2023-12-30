-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_account_metadata
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__efp_account_metadata AS
SELECT
  a.chain_id,
  a.contract_address,
  a.address,
  a.key,
  a.value,
  a.block_number,
  a.transaction_index,
  a.log_index
FROM
  PUBLIC.view__efp_account_metadata__events a
  INNER JOIN (
    SELECT
      chain_id,
      contract_address,
      address,
      KEY,
      MAX(
        PUBLIC.sort_key (block_number, transaction_index, log_index)
      ) AS latest_sort_key
    FROM
      PUBLIC.view__efp_account_metadata__events
    GROUP BY
      chain_id,
      contract_address,
      address,
      KEY
  ) b ON a.chain_id = b.chain_id
  AND a.contract_address = b.contract_address
  AND a.address = b.address
  AND a.key = b.key
  AND PUBLIC.sort_key (a.block_number, a.transaction_index, a.log_index) = b.latest_sort_key;



-- migrate:down