-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_recommended
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_recommended (
    "index" BIGINT NOT NULL,
    "name" TEXT NOT NULL,
    "address" types.eth_address NOT NULL,
    "avatar" TEXT,
    "header" TEXT,
    "class" TEXT,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ("address")
  );

-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_recommended
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_recommended CASCADE;