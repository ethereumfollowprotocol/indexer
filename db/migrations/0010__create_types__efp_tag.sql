--migrate:up
-------------------------------------------------------------------------------
-- Domain: types.efp_tag
--
-- Description: A tag for a list record
-- Constraints: Must be a non-empty string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN
  types.efp_tag AS VARCHAR(255) NOT NULL CHECK (LENGTH(VALUE) > 0);



-------------------------------------------------------------------------------
-- Domain: types.efp_tag_nullable
--
-- Description: A tag for a list record, or NULL.
-- Constraints: Must be a non-empty string of 255 characters or less
-------------------------------------------------------------------------------
CREATE DOMAIN
  types.efp_tag__nullable AS VARCHAR(255);



--migrate:down