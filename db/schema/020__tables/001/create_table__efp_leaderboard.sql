-- migrate:up
-------------------------------------------------------------------------------
-- Table: efp_leaderboard
-------------------------------------------------------------------------------
CREATE TABLE
  public.efp_leaderboard (
    "address" types.eth_address NOT NULL,
    "name" TEXT,
    "avatar" TEXT,
    "mutuals_rank" BIGINT,
    "followers_rank" BIGINT,
    "following_rank" BIGINT,
    "blocks_rank" BIGINT,
    "top8_rank" BIGINT,
    "mutuals" BIGINT DEFAULT 0,
    "following" BIGINT DEFAULT 0,
    "followers" BIGINT DEFAULT 0,
    "blocks" BIGINT DEFAULT 0,
    "top8" BIGINT DEFAULT 0,
    created_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP
    WITH
      TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ("address")
  );

CREATE TRIGGER
  update_efp_leaderboard_updated_at BEFORE
UPDATE
  ON public.efp_leaderboard FOR EACH ROW
EXECUTE
  FUNCTION public.update_updated_at_column();

-- migrate:down
-------------------------------------------------------------------------------
-- Undo Table: efp_leaderboard
-------------------------------------------------------------------------------
DROP TABLE
  IF EXISTS public.efp_leaderboard CASCADE;