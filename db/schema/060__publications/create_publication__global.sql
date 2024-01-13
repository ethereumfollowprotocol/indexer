-- migrate:up
DROP PUBLICATION IF EXISTS global_publication;
CREATE PUBLICATION global_publication FOR ALL TABLES;
-- migrate:down
