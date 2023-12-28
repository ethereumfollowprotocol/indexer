# syntax=docker/dockerfile:1
FROM ghcr.io/foundry-rs/foundry:latest

ENV FORK_URL=""

# Set the entrypoint to the forge deployment command
ENTRYPOINT \
  if ! [ -z "$FORK_URL" ]; then \
    anvil --host 0.0.0.0 --fork-url $FORK_URL --port $PORT; \
  else \
    anvil --host 0.0.0.0 --port $PORT; \
  fi;
