-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_debug_total_supply
-- Description: Retrieves the total supply for the list registry.
-- Parameters: None
-- Returns: A bigint representing the total supply of the list registry.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_debug_total_supply() RETURNS BIGINT AS $$
DECLARE
  total_supply BIGINT;
BEGIN
  SELECT COUNT(DISTINCT token_id) INTO total_supply
  FROM public.view__events__efp_list_nfts;

  RETURN total_supply;
END;
$$ LANGUAGE plpgsql;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: get_debug_total_supply
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS query.get_debug_total_supply();