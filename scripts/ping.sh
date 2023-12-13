#!/usr/bin/env bash

function query_eth_blockNumber() {
    local host=$1
    echo
    echo
    echo "========================================"
    echo "Querying: $host"
    echo "========================================"


    (set -x; curl http://$host:8545 --request POST \
      --header "Content-Type: application/json" \
      --connect-timeout 3 \
      --silent \
      --show-error \
      --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' && set +x)
      if [ $? -eq 0 ]; then
        # green success message
        echo -e "\n\033[0;32mhttp://$host:8545 connection succeeded\033[0m"
      else
        # red error message
        echo -e "\033[0;31mhttp://$host:8545 Failed to connect\033[0m"
      fi
    echo
}

echo "Ping starting..."

# List of hosts to query
hosts=("localhost" "0.0.0.0" "127.0.0.1" "host.docker.internal")

# Loop through and query each host
for host in "${hosts[@]}"; do
    query_eth_blockNumber $host
done

echo "Ping finished."
