-- migrate:up
-------------------------------------------------------------------------------
-- View: view__efp_stats
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__efp_stats AS
SELECT 
    ( SELECT count(DISTINCT(record_data))
        FROM public.efp_list_records r
        WHERE r.record_version = 1 
        AND r.record_type = 1) AS address_count,
    ( SELECT count(*) AS count
        FROM public.efp_lists) AS list_count,
    ( SELECT count(*) AS count
        FROM public.events
        WHERE events.event_name::text = 'ListOp'::text) AS list_op_count,
    ( SELECT count(DISTINCT events.event_args ->> 'to'::text) AS count
        FROM public.events
        WHERE events.event_name::text = 'Transfer'::text AND events.event_args @> '{"from": "0x0000000000000000000000000000000000000000"}'::jsonb) AS user_count;





-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__efp_stats
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__efp_stats CASCADE;