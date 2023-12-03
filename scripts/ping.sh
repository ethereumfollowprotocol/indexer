#!/usr/bin/env bash

function query_eth_blockNumber() {
    local host=$1
    echo
    echo "Querying: $host"
    echo

    curl http://$host:8545 --request POST \
      --header "Content-Type: application/json" \
      --connect-timeout 3 \
      --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
}

# List of hosts to query
hosts=("127.0.0.1" "localhost" "0.0.0.0" "host.docker.internal")

# Loop through and query each host
for host in "${hosts[@]}"; do
    query_eth_blockNumber $host
done
