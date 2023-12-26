-- migrate:up
-- Create Extensions: pgcrypto for cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';

CREATE SCHEMA "types";

CREATE SCHEMA "query";

-- migrate:down