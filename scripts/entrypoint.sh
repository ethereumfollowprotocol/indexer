#!/bin/sh

echo
echo "Starting indexer container..."
echo

echo "Current database migrations status:"
bunx dbmate status
echo

echo "Setting up database..."
bunx dbmate up
echo

echo "Generating introspection..."
bun database:introspect
bun format
echo

echo "Current database migrations status:"
bunx dbmate status
echo

bun --hot --watch ./src/index.ts

tail -f /dev/null
