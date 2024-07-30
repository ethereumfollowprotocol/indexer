-- migrate:up
-------------------------------------------------------------------------------
-- Function: get_debug_num_events
-- Description: Retrieves the number of rows in the events table.
-- Parameters: None
-- Returns: A bigint representing the number of rows in the events table.
-------------------------------------------------------------------------------
CREATE
OR REPLACE FUNCTION query.get_debug_num_events() RETURNS BIGINT AS $$
DECLARE
  num_events BIGINT;
BEGIN
  SELECT COUNT(*) INTO num_events
  FROM public.events;

  RETURN num_events;
END;
$$ LANGUAGE plpgsql;



-- migrate:down
-------------------------------------------------------------------------------
-- Undo Function: get_debug_num_events
-------------------------------------------------------------------------------
DROP FUNCTION
  IF EXISTS query.get_debug_num_events();