-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_recent_activity
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_recent_activity (
    "address" types.eth_address NOT NULL,
    "name" TEXT,
    "avatar" TEXT,
    "header" TEXT,
    "followers" BIGINT DEFAULT 0,
    "following" BIGINT DEFAULT 0,
    "_index" BIGINT DEFAULT 0,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ("address")
  );

CREATE TRIGGER
  update_efp_recent_activity_updated_at BEFORE
UPDATE
  ON public.efp_recent_activity FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();

-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_recent_activity
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_recent_activity CASCADE;