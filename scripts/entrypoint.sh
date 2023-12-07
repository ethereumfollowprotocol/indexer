#!/bin/sh

set -e

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Starting indexer container...:"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
echo "========================================"
echo "Current database migrations status:"
bunx dbmate status
echo "========================================"
echo
echo "========================================"
echo "Setting up database and generating types…"
bunx dbmate up
echo "========================================"
echo
echo "========================================"
echo "Current database migrations status:"
bunx dbmate status
echo "========================================"

exec "$@"
