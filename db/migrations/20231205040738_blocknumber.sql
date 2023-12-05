-- migrate:up
ALTER TABLE "events" ALTER COLUMN "id" SET DATA TYPE text;

ALTER TABLE "events" ALTER COLUMN "id" SET DEFAULT generate_ulid();

ALTER TABLE "events"
ALTER COLUMN "block_number"
SET DATA TYPE bigint;

ALTER TABLE "events"
ADD
    COLUMN "processed" text DEFAULT 'false' NOT NULL;

DO $$ BEGIN ALTER 
	TABLE "activity"
	ADD
	    CONSTRAINT "activity_actor_address_user_wallet_address_fk" FOREIGN KEY ("actor_address") REFERENCES "user"("wallet_address") ON DELETE restrict ON UPDATE cascade;
	EXCEPTION WHEN duplicate_object THEN null;
	END $$;

-- migrate:down

