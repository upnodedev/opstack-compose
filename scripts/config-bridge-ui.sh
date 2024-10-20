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
VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS=$(jq -r '.L2OutputOracleProxy' ./data/deployments/artifact.json)
VITE_PORTAL_PROXY_ADDRESS=$(jq -r '.OptimismPortalProxy' ./data/deployments/artifact.json)
VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS=$(jq -r '.L1StandardBridgeProxy' ./data/deployments/artifact.json)
VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS=$(jq -r '.L1CrossDomainMessengerProxy' ./data/deployments/artifact.json)
VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY=$(jq -r '.L1ERC721BridgeProxy' ./data/deployments/artifact.json)

if grep -q "^VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS=" ./.env; then
    $SED_COMMAND "s/^VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS=.*/VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS=${VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS}/" ./.env
else
    echo "VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS=${VITE_L2_OUTPUT_ORACLE_PROXY_ADDRESS}" >> ./.env
fi

if grep -q "^VITE_PORTAL_PROXY_ADDRESS=" ./.env; then
    $SED_COMMAND "s/^VITE_PORTAL_PROXY_ADDRESS=.*/VITE_PORTAL_PROXY_ADDRESS=${VITE_PORTAL_PROXY_ADDRESS}/" ./.env
else
    echo "VITE_PORTAL_PROXY_ADDRESS=${VITE_PORTAL_PROXY_ADDRESS}" >> ./.env
fi

if grep -q "^VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS=" ./.env; then
    $SED_COMMAND "s/^VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS=.*/VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS=${VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS}/" ./.env
else
    echo "VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS=${VITE_L1_STANDARD_BRIDGE_PROXY_ADDRESS}" >> ./.env
fi

if grep -q "^VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS=" ./.env; then
    $SED_COMMAND "s/^VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS=.*/VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS=${VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS}/" ./.env
else
    echo "VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS=${VITE_L1_CROSS_DOMAIN_MESSENGER_PROXY_ADDRESS}" >> ./.env
fi

if grep -q "^VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY=" ./.env; then
    $SED_COMMAND "s/^VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY=.*/VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY=${VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY}/" ./.env
else
    echo "VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY=${VITE_L1_ERC721_BRIDGE_ADDRESS_PROXY}" >> ./.env
fi
