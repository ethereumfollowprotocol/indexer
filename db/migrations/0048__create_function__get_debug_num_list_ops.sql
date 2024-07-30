-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_debug_num_list_ops
-- Description: Retrieves the number of list_ops.
-- Parameters: None
-- Returns: A bigint representing the number of list_ops.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_debug_num_list_ops() RETURNS BIGINT AS $$
DECLARE
  num_list_ops BIGINT;
BEGIN
  SELECT COUNT(*) INTO num_list_ops
  FROM public.view__events__efp_list_ops;

  RETURN num_list_ops;
END;
$$ LANGUAGE plpgsql;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: get_debug_num_list_ops
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS query.get_debug_num_list_ops();