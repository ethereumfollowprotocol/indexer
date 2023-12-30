#!/usr/bin/env bash

set -e

# Directories containing your current db structure
migrations_dir="db/migrations"
schema_dir="db/schema"
queries_dir="db/queries"
functions_dir="db/functions"

# Create the migrations directory if it does not exist
mkdir -p "$migrations_dir"

# clean up db/migrations folder
rm -rf ${migrations_dir}/*

# Array to hold all SQL files
declare -a sql_files

# Helper function to aggregate SQL files
aggregate_files() {
  local dir=$1
  while IFS= read -r -d $'\0' file; do
    sql_files+=("$file")
  done < <(find "$dir" -type f -name '*.sql' -print0 | sort -z)
}

# Aggregate files from schema and queries directories
aggregate_files "$schema_dir"
aggregate_files "$queries_dir"
aggregate_files "$functions_dir"

# Counter to prefix file names to preserve order
counter=1

# Iterate over the array and process each file
for sql_file in "${sql_files[@]}"; do
  sql_file_basename=$(basename "$sql_file")
  # strip leading numbers and underscores
  sql_file_basename=${sql_file_basename##[0-9][0-9][0-9]__}

  # Construct new file name with a counter prefix
  new_file_name=$(printf "%04d__%s" "$counter" "$sql_file_basename")

  # Copy the file to migrations directory
  cp "$sql_file" "$migrations_dir/$new_file_name"

  echo "$migrations_dir/$new_file_name"

  # Increment counter
  ((counter++))
done

bunx dbmate up

# bun database:generate-types
