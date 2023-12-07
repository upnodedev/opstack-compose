#!/bin/bash

# Function to update or add a key-value pair in a JSON file
update_json() {
  local key=$1
  local value=$2
  local json_file=$3
  local jq_filter

  # Check if the value is numeric or boolean; otherwise, treat as a string
  if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" || "$value" == "false" ]]; then
    jq_filter=".$key=$value"
  else
    jq_filter=".$key=\"$value\""
  fi

  # Update or add the key-value pair
  jq "$jq_filter" "$json_file" > temp.json && mv temp.json "$json_file"
}

# Paths to the JSON config files
config_file="/app/data/configurations/deploy-config.json"
custom_config_file="/app/deploy-custom-config.json"

# Iterate and update/add each key-value pair from the custom config file
jq -r 'to_entries|map("\(.key) \(.value)")|.[]' "$custom_config_file" | while read -r key value; do
  update_json "$key" "$value" "$config_file"
done

# Clean up
rm -f temp.json
