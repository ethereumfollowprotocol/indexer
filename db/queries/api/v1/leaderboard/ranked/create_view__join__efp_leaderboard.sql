-- migrate:up
-------------------------------------------------------------------------------
-- View: view__join__efp_leaderboard
-------------------------------------------------------------------------------
CREATE
OR REPLACE VIEW PUBLIC.view__join__efp_leaderboard AS
 SELECT fers.address,
    COALESCE(ens.name) AS ens_name,
    COALESCE(ens.avatar) AS ens_avatar,
    mut.mutuals_rank,
    fers.followers_rank,
    fing.following_rank,
    blocks.blocked_rank AS blocks_rank,
    top8.top8_rank AS top8_rank,
    COALESCE(mut.mutuals, 0::bigint) AS mutuals,
    COALESCE(fers.followers_count, 0::bigint) AS followers,
    COALESCE(fing.following_count, 0::bigint) AS following,
    COALESCE(blocks.blocked_count, 0::bigint) AS blocks,
    COALESCE(top8.top8_count, 0::bigint) AS top8
   FROM query.get_leaderboard_followers(10000::bigint) fers(address, followers_count, followers_rank)
     LEFT JOIN query.get_leaderboard_following(10000::bigint) fing(address, following_count, following_rank) ON fing.address::text = fers.address::text
     LEFT JOIN query.get_leaderboard_blocked(10000::bigint) blocks(address, blocked_count, blocked_rank) ON blocks.address::text = fers.address::text
     LEFT JOIN query.get_leaderboard_top8(10000::bigint) top8(address, top8_count, top8_rank) ON top8.address::text = fers.address::text
     LEFT JOIN public.view__events__efp_leaderboard_mutuals mut ON mut.leader::text = fers.address::text
     LEFT JOIN public.ens_metadata ens ON ens.address::text = fers.address::text
  ORDER BY mut.mutuals DESC NULLS LAST;

-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__join__efp_leaderboard
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__join__efp_leaderboard CASCADE;