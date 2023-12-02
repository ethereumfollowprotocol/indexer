# syntax=docker/dockerfile:1
FROM oven/bun:latest as installer

# This is WIP atm

WORKDIR /usr/src/app

COPY . /usr/src/app/

RUN chmod +x ./scripts/entrypoint.sh

ENTRYPOINT ["./scripts/entrypoint.sh"]
CMD ["bun", "--watch", "./src/index.ts"]
