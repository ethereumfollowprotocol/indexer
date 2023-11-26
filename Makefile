include .env
export

UNIX_TIMESTAMP := $(shell date +%s)

.PHONY: save-schema-snapshot
dump-schema:
	@bunx dbmate --schema-file=./drizzle/schema/${UNIX_TIMESTAMP}.sql --url="${DATABASE_URL}" dump

.PHONY: list-schemas
list-schemas:
	@cat ./drizzle/README.md
	@printf "$(CYAN)%-30s | %-20s$(RESET)\n" "File" "Last Modified"
	@for file in drizzle/schema/*.sql; do \
		printf "$(GREEN)%-30s | $(WHITE)%s$(RESET)\n" "$$file" "$$(date -u -r $$file +'%Y-%m-%d %H:%M:%S')"; \
	done
