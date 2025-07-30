# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Development
- `bun dev` - Start development server with hot reload
- `bun build` - Build production bundle using Bun
- `bun test` - Run tests with Vitest
- `bun test:ui` - Run tests with Vitest UI
- `bun test:typecheck` - Run type checking tests
- `bun lint` - Run BiomeJS linter and type checking
- `bun typecheck` - Run TypeScript type checking only
- `bun format` - Format SQL and TypeScript code

### Database Operations
- `bun database:up` - Create database and run migrations
- `bun database:reset` - Drop database, recreate, and generate types
- `bun database:generate-types` - Generate TypeScript types from database schema
- `bun database:status` - Check migration status
- `bun database:drop` - Drop the database entirely

### Docker/Infrastructure
- `bun up` - Start database and indexer containers
- `bun upd` - Start containers in detached mode
- `bun down` - Stop all containers
- `bun database` - Start only database container
- `bun indexer` - Start only indexer container
- `bun drop` - Stop containers and remove volumes

## Architecture Overview

This is an Ethereum Follow Protocol (EFP) indexer that watches blockchain events and stores them in a PostgreSQL database.

### Core Components

**Event Processing Pipeline:**
1. **Contract Event Publishers** (`src/pubsub/publisher/contract-event-publisher.ts`) - Listen to specific EFP contracts for events
2. **Event Interleaver** (`src/pubsub/publisher/event-interleaver.ts`) - Merges events from multiple contracts into chronological order
3. **Event Uploader** (`src/pubsub/subscriber/event-uploader.ts`) - Persists events to database

**Key Files:**
- `src/index.ts` - Main entry point, handles database setup and starts event watching
- `src/watch.ts` - Orchestrates the event watching system for all EFP contracts
- `src/env.ts` - Environment variable configuration with validation
- `src/database/index.ts` - Kysely database client with reconnection logic

### Contract Integration
The indexer watches these EFP contracts:
- **EFPAccountMetadata** - Account metadata updates
- **EFPListRegistry** - List registry operations
- **EFPListRecords** - List record operations (follows, blocks, mutes)

### Database Schema
- Complex PostgreSQL schema in `db/schema/` with extensive migrations
- Database functions and views for API queries in `db/queries/api/`
- Type generation via `kysely-codegen` creates `src/database/generated/index.ts`

### Environment Configuration
Key environment variables (see `src/env.ts`):
- `DATABASE_URL` - PostgreSQL connection string
- `CHAIN_ID` - Ethereum chain ID to index
- `EFP_CONTRACT_*` - Contract addresses for each EFP component
- `PRIMARY_RPC_*` / `SECONDARY_RPC_*` - RPC endpoints per chain
- `START_BLOCK` - Block to start indexing from
- `RECORDS_ONLY` - Index only list records (not metadata)

## Development Workflow

1. **Database Changes**: Update SQL in `db/migrations/`, then run `bun database:reset`
2. **Testing**: Database must be running (`bun database`) before running tests
3. **Type Safety**: Always run `bun lint` after code changes
4. **Local Development**: Use `bun dev` for hot reload during development

## Tech Stack
- **Runtime**: Bun
- **Language**: TypeScript with strict configuration
- **Database**: PostgreSQL with Kysely query builder
- **Blockchain**: Viem for Ethereum interaction
- **Linting**: BiomeJS
- **Testing**: Vitest
- **Containerization**: Docker Compose