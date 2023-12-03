# syntax=docker/dockerfile:1
FROM oven/bun:latest as installer

# This is WIP atm

RUN apt-get update && apt-get install --yes \
  curl \
  git \
  build-essential \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY bun.lockb bun.lockb
COPY package.json package.json

RUN bun install

COPY . .

# RUN chmod +x ./scripts/entrypoint.sh

# ENTRYPOINT ["./scripts/entrypoint.sh"]
CMD ["bun", "--watch", "./src/index.ts"]
