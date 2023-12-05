-- migrate:up

ALTER TABLE public.events ALTER COLUMN block_number TYPE bigint;

-- migrate:down
