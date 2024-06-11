-- migrate:up
-------------------------------------------------------------------------------
-- View: view__latest_follows
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__latest_follows AS
SELECT DISTINCT '0x' || LPAD(address, 40, '0') as address FROM (
	SELECT TRIM('0x01010101' FROM op) as address 
	FROM public.efp_list_ops 
	WHERE opcode = 1  
	GROUP BY op, chain_id, contract_address, slot 
	ORDER BY updated_at DESC
	LIMIT 100
) LIMIT 10;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__latest_follows
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__latest_follows CASCADE;