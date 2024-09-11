-- migrate:up
-------------------------------------------------------------------------------
-- Table: ens_metadata
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_poap_links (
    "link" TEXT NOT NULL,
    "claimed" BOOLEAN NOT NULL,
    "claimant" TEXT,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ("link")
  );

CREATE TRIGGER
  update_efp_poap_links_updated_at BEFORE
UPDATE
  ON public.efp_poap_links FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();

-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_poap_links
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_poap_links CASCADE;