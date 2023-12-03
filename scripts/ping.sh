#!/usr/bin/env bash

echo "127.0.0.1\n"

curl http://127.0.0.1:8545 --request POST \
  --header "Content-Type: application/json" \
  --connect-timeout 3 \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

echo "localhost\n"

curl http://localhost:8545 --request POST \
  --header "Content-Type: application/json" \
  --connect-timeout 3 \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

echo -e "0.0.0.0\n"

curl http://0.0.0.0:8545 --request POST \
  --header "Content-Type: application/json" \
  --connect-timeout 3 \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
