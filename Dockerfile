# syntax=docker/dockerfile:1
FROM oven/bun:slim

WORKDIR /usr/src/app

RUN apt-get update --yes \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/apt/lists/*

COPY bun.lockb package.json ./

ENV NODE_ENV="production"

RUN bun install --production --frozen-lockfile

COPY . .

CMD ["bun", "./src/index.ts"]
