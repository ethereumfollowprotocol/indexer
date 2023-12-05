
> [!NOTE]
> The project is under active development.

<br />

<p align="center">
  <a href="https://ethfollow.xyz" target="_blank" rel="noopener noreferrer">
    <img width="275" src="https://docs.ethfollow.xyz/logo.png" alt="EFP logo" />
  </a>
</p>
<br />
<p align="center">
  <a href="https://pr.new/ethereumfollowprotocol/indexer"><img src="https://developer.stackblitz.com/img/start_pr_dark_small.svg" alt="Start new PR in StackBlitz Codeflow" /></a>
  <a href="https://discord.ethfollow.xyz"><img src="https://img.shields.io/badge/chat-discord-blue?style=flat&logo=discord" alt="discord chat" /></a>
  <a href="https://x.com/ethfollowpr"><img src="https://img.shields.io/twitter/follow/ethfollowpr?label=%40ethfollowpr&style=social&link=https%3A%2F%2Fx.com%2Fethfollowpr" alt="x account" /></a>
</p>

<h1 align="center" style="font-size: 2.75rem; font-weight: 900; color: white;">Ethereum Follow Protocol Indexer</h1>

> A native Ethereum protocol for following and tagging Ethereum accounts.

## Important links

- Documentation: [**docs.ethfollow.xyz/api**](https://docs.ethfollow.xyz/api)

## Getting started with development

### Prerequisites

- [Bun runtime](https://bun.sh/) (latest version)
- [Node.js](https://nodejs.org/en/) (LTS which is currently 20)

### Installation

```bash
git clone https://github.com/ethereumfollowprotocol/indexer.git && cd indexer
```

> [!NOTE]
> If vscode extensions behave weirdly or you stop getting type hints, run CMD+P and type `> Developer: Restart Extension Host` to restart the extension host.

```bash
# upgrade bun to make sure you have the latest version then install dependencies
bun upgrade && bun install
```

### Environment Variables

```bash
cp .env.example .env
```

### Database

- [PostgreSQL](https://www.postgresql.org/)
- [dbmate](https://github.com/amacneil/dbmate) (for migrations)

Migration files are located in `./db/migrations`. `dbmate` commands:

```bash
bunx dbmate --help    # print usage help
bunx dbmate new       # generate a new migration file
bunx dbmate up        # create the database (if it does not already exist) and run any pending migrations
bunx dbmate create    # create the database
bunx dbmate drop      # drop the database
bunx dbmate migrate   # run any pending migrations
bunx dbmate rollback  # roll back the most recent migration
bunx dbmate down      # alias for rollback
bunx dbmate status    # show the status of all migrations (supports --exit-code and --quiet)
bunx dbmate dump      # write the database schema.sql file
bunx dbmate wait      # wait for the database server to become available
```


____
TODO: Continue documentation
____

<br />

Follow [**@ethfollowpr**](https://x.com/ethfollowpr) on **𝕏** for updates and join the [**Discord**](https://discord.ethfollow.xyz) to get involved.
 