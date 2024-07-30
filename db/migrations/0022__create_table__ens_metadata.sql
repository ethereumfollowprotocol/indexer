-- migrate:up
-------------------------------------------------------------------------------
-- Table: ens_metadata
-------------------------------------------------------------------------------
CREATE TABLE
  public.ens_metadata (
    "name" TEXT NOT NULL,
    "address" types.eth_address NOT NULL,
    "avatar" TEXT,
    "display" TEXT,
    "records" TEXT[],
    "chains" TEXT[],
    "fresh" BIGINT,
    "resolver" types.eth_address,
    "errors" TEXT,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ("address", "name")
  );

CREATE TRIGGER
  update_ens_metadata_updated_at BEFORE
UPDATE
  ON public.ens_metadata FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();

-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: ens_metadata
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.ens_metadata CASCADE;