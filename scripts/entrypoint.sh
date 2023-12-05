#!/bin/sh

echo
echo "Starting indexer container..."
echo

echo "Current database migrations status:"
bunx dbmate status
echo

echo "Setting up database and generating types..."
bunx dbmate up
echo

echo "Current database migrations status:"
bunx dbmate status
echo

exec "$@"
