#!/bin/bash

# Detect OS and set sed options
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS (BSD sed) requires a backup extension, use '' to disable
    SED_COMMAND="sed -i ''"
else
    # Linux (GNU sed) can work with -i without an extension
    SED_COMMAND="sed -i"
fi

# Read the portal addresses from artifact.json
L1_PORTAL_ADDRESS=$(jq -r '.OptimismPortalProxy' ./data/deployments/artifact.json)

# Replace L1_PORTAL_ADDRESS if it exists in .env, otherwise append it
if grep -q "^L1_PORTAL_ADDRESS=" ./.env; then
    $SED_COMMAND "s/^L1_PORTAL_ADDRESS=.*/L1_PORTAL_ADDRESS=${L1_PORTAL_ADDRESS}/" ./.env
else
    echo "L1_PORTAL_ADDRESS=${L1_PORTAL_ADDRESS}" >> ./.env
fi
