#!/usr/bin/env bash

set -e

# Create a temporary config file
config_file=$(mktemp)
echo '{"language":"postgresql","uppercase":"true","linesBetweenQueries":3}' > "$config_file"

# Create a temporary directory for output files
output_dir=$(mktemp -d)
num_cpus=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)

# Run formatting in parallel, but store outputs in temporary files
find db/migrations -type f | sort | xargs -I {} -P "$num_cpus" sh -c 'file_base=$(basename "$1"); bun sql-formatter --fix --language=postgresql --config "'"$config_file"'" "$1" > "'"$output_dir"'/$file_base.out" 2>&1 && echo "$file_base" > "'"$output_dir"'/$file_base.done"' _ {}

# Print outputs in the original order
for file in $(find db/migrations -type f | sort); do
    file_base=$(basename "$file")
    # Wait for the done file to ensure the task is completed
    while [ ! -f "$output_dir/$file_base.done" ]; do
        sleep 0.1
    done
    # Print the output
    echo "$file"
done

# Clean up
rm "$config_file"
rm -r "$output_dir"
