#!/bin/bash

# Ensure script stops on first error
set -e

# Clone the repositories
/app/clone-repos.sh

# Setting an environment variable for deployment
export IMPL_SALT=$(openssl rand -hex 32)

# Check if both L1_BLOCKHASH and L1_TIMESTAMP are set or unset
if [ -n "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ] || [ -z "$L1_BLOCKHASH" ] && [ -n "$L1_TIMESTAMP" ]; then
  echo "Error: Both L1_BLOCKHASH and L1_TIMESTAMP must be set or unset."
  exit 1
elif [ -z "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ]; then
  # Fetch block details if both variables are unset
  echo "Fetching block details from L1_RPC_URL..."
  block=$(cast block finalized --rpc-url $L1_RPC_URL)
  export L1_TIMESTAMP=$(echo "$block" | awk '/timestamp/ { print $2 }')
  export L1_BLOCKHASH=$(echo "$block" | awk '/hash/ { print $2 }')
fi

# Build the Optimism Monorepo
cd /app/data/optimism
pnpm install
make op-node op-batcher op-proposer
pnpm build

# Build op-geth
cd /app/data/op-geth
make geth

cd /app/data/optimism/packages/contracts-bedrock

# Check if deploy-config.json exists
if [ -f "/app/deploy-config.json" ]; then
  # Populate deploy-config.json with env variables
  echo "Populating deploy-config.json with env variables..."
  # NOTE: scripts/Deploy.s.sol:Deploy expects the deploy-config.json file to be in ./deploy-config
  envsubst < /app/deploy-config.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/$DEPLOYMENT_CONTEXT.json
else
  # If deploy-config.json does not exist, use config.sh to generate it
  echo "Generating deploy-config.json..."
  ./scripts/getting-started/config.sh
fi

cp -f ./deploy-config/$DEPLOYMENT_CONTEXT.json /app/data/configurations/deploy-config.json

# Deploy the L1 contracts
forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL
forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $L1_RPC_URL

rm -rf /app/data/deployments/$DEPLOYMENT_CONTEXT
cp -r /app/data/optimism/packages/contracts-bedrock/deployments/$DEPLOYMENT_CONTEXT /app/data/deployments

# Generate the L2 config files
cd /app/data/optimism/op-node
go run cmd/main.go genesis l2 \
  --deploy-config /app/data/configurations/deploy-config.json \
  --deployment-dir /app/data/deployments/$DEPLOYMENT_CONTEXT/ \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc $L1_RPC_URL
openssl rand -hex 32 > jwt.txt
cp genesis.json /app/data/op-geth
cp jwt.txt /app/data/op-geth

# Copy genesis.json and rollup.json to /app/data/configurations/
cp genesis.json /app/data/configurations/
cp rollup.json /app/data/configurations/

# Initialize op-geth
cd /app/data/op-geth
mkdir datadir
build/bin/geth init --datadir=datadir genesis.json

exec "$@"
