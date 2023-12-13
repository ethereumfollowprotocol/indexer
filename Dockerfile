# syntax=docker/dockerfile:1
FROM oven/bun:latest as setup

RUN apt-get update \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

COPY bun.lockb package.json ./

RUN bun install --production --frozen-lockfile

COPY . .

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bun", "./src/index.ts"]
