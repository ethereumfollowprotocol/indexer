-- migrate:up
-------------------------------------------------------------------------------
-- View: view__discover
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW PUBLIC.view__discover AS
SELECT
	address,
	name,
	avatar,
	followers,
	following
FROM (
	(SELECT 
	    lf.address,
	    l.name,
	    l.avatar,
	    l.followers,
	    l.following,
		lf._index
	FROM public.view__latest_leaders lf
	JOIN public.efp_leaderboard l ON l.address = lf.address )
	UNION
	(SELECT 
	    r.address,
	    l.name,
	    l.avatar,
	    l.followers,
	    l.following,
		r._index
	FROM public.view__latest_follows r
	JOIN public.efp_leaderboard l ON l.address = r.address
	)
)
ORDER BY _index ASC;





-- migrate:down
-------------------------------------------------------------------------------
-- Undo View: view__discover
-------------------------------------------------------------------------------
DROP VIEW
  IF EXISTS PUBLIC.view__discover CASCADE;