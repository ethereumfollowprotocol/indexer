-- migrate:up
DO $$ BEGIN
 CREATE TYPE "action" AS ENUM('unmute', 'mute', 'unblock', 'block', 'unfollow', 'follow');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "schema_migrations" (
	"version" varchar(128) PRIMARY KEY NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "activity" (
	"id" text PRIMARY KEY DEFAULT generate_ulid() NOT NULL,
	"action" "action" NOT NULL,
	"actor_address" varchar NOT NULL,
	"target_address" varchar NOT NULL,
	"action_timestamp" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	"updated_at" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "user" (
	"id" text PRIMARY KEY DEFAULT generate_ulid() NOT NULL,
	"wallet_address" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	"updated_at" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
	CONSTRAINT "user_wallet_address_key" UNIQUE("wallet_address")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "events" (
	"id" text PRIMARY KEY DEFAULT generate_ulid() NOT NULL,
	"transaction_hash" varchar(66) NOT NULL,
	"block_number" bigint NOT NULL,
	"contract_address" varchar(42) NOT NULL,
	"event_name" varchar(255) NOT NULL,
	"event_parameters" jsonb NOT NULL,
	"timestamp" timestamp with time zone NOT NULL,
	"processed" text DEFAULT 'false' NOT NULL
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "index_activity_action" ON "activity" ("action");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "index_activity_actor" ON "activity" ("actor_address");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "index_activity_target" ON "activity" ("target_address");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_transaction_hash" ON "events" ("transaction_hash");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_contract_address" ON "events" ("contract_address");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_event_name" ON "events" ("event_name");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_block_number" ON "events" ("block_number");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "activity" ADD CONSTRAINT "activity_actor_address_fkey" FOREIGN KEY ("actor_address") REFERENCES "user"("wallet_address") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "activity" ADD CONSTRAINT "activity_actor_address_user_wallet_address_fk" FOREIGN KEY ("actor_address") REFERENCES "user"("wallet_address") ON DELETE restrict ON UPDATE cascade;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

-- migrate:down

