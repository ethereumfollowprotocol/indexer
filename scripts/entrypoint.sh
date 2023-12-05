#!/bin/sh

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Starting indexer container...:"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
echo "========================================"
Current "database migrations status:"
bunx dbmate status
echo "========================================"

exec "$@"
