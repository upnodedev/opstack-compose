#!/bin/bash

# Ensure script stops on first error
set -e

# Clone repositories if necessary
/app/clone-repos.sh

# Check and build binaries if at least one doesn't exist
if [ ! -f "$BIN_DIR/op-node" ] || [ ! -f "$BIN_DIR/op-batcher" ] || [ ! -f "$BIN_DIR/op-proposer" ] || [ ! -f "$BIN_DIR/geth" ]; then
  # Build op-node, op-batcher and op-proposer
  cd "$OPTIMISM_DIR"
  pnpm install
  make op-node op-batcher op-proposer
  pnpm build

  # Copy binaries to the bin volume
  cp -f "$OPTIMISM_DIR"/op-node/bin/op-node "$BIN_DIR"/
  cp -f "$OPTIMISM_DIR"/op-batcher/bin/op-batcher "$BIN_DIR"/
  cp -f "$OPTIMISM_DIR"/op-proposer/bin/op-proposer "$BIN_DIR"/

  # Build op-geth
  cd "$OP_GETH_DIR"
  make geth

  # Copy geth binary to the bin volume
  cp ./build/bin/geth "$BIN_DIR"/
fi

# Create jwt.txt if it does not exist
[ -f "$CONFIG_PATH/jwt.txt" ] || openssl rand -hex 32 > "$CONFIG_PATH"/jwt.txt

# Check if all required genesis files exist
if [ -f "$CONFIG_PATH/genesis.json" ] && [ -f "$CONFIG_PATH/rollup.json" ]; then
  echo "L2 genesis files are present, skipping prepare.sh script."
  exec "$@"
  exit 0
elif [ -f "$CONFIG_PATH/genesis.json" ] || [ -f "$CONFIG_PATH/rollup.json" ]; then
  echo "Error: One of the genesis.json or rollup.json files is missing."
  exit 1
fi

# If no genesis files exist, continue with the script
echo "No required genesis files are present, continuing script execution."

# Check if all or none of the private keys are provided
if [ -z "$BATCHER_PRIVATE_KEY" ] && [ -z "$PROPOSER_PRIVATE_KEY" ] && [ -z "$SEQUENCER_PRIVATE_KEY" ]; then
  echo "All private keys are missing, fetching from AWS Secrets Manager..."
  secrets=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_ARN" | jq '.SecretString | fromjson')

  BATCHER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.BATCHER_PRIVATE_KEY')"
  PROPOSER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.PROPOSER_PRIVATE_KEY')"
  SEQUENCER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.SEQUENCER_PRIVATE_KEY')"

  export BATCHER_PRIVATE_KEY PROPOSER_PRIVATE_KEY SEQUENCER_PRIVATE_KEY
elif [ -n "$BATCHER_PRIVATE_KEY" ] && [ -n "$PROPOSER_PRIVATE_KEY" ] && [ -n "$SEQUENCER_PRIVATE_KEY" ]; then
  echo "All private keys are provided, continuing..."
else
  echo "Error: Private keys must be all provided or all fetched from AWS Secrets Manager."
  exit 1
fi

# Check if both L1_BLOCKHASH and L1_TIMESTAMP are set or unset
if [ -n "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ] || [ -z "$L1_BLOCKHASH" ] && [ -n "$L1_TIMESTAMP" ]; then
  echo "Error: Both L1_BLOCKHASH and L1_TIMESTAMP must be set or unset."
  exit 1
elif [ -z "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ]; then
  # Fetch block details if both variables are unset
  echo "Fetching block details from L1_RPC_URL..."
  block=$(cast block finalized --rpc-url "$L1_RPC_URL")
  L1_TIMESTAMP=$(echo "$block" | awk '/timestamp/ { print $2 }')
  export L1_TIMESTAMP
  L1_BLOCKHASH=$(echo "$block" | awk '/hash/ { print $2 }')
  export L1_BLOCKHASH
fi

L1_CHAIN_ID=$(cast chain-id --rpc-url "$L1_RPC_URL")
export L1_CHAIN_ID

# Source the utils.sh file
# shellcheck disable=SC1091
source /app/utils.sh

# Derive addresses from private keys and check for conflicts
derive_and_check "ADMIN_PRIVATE_KEY" "GS_ADMIN_ADDRESS"
derive_and_check "BATCHER_PRIVATE_KEY" "GS_BATCHER_ADDRESS"
derive_and_check "PROPOSER_PRIVATE_KEY" "GS_PROPOSER_ADDRESS"
derive_and_check "SEQUENCER_PRIVATE_KEY" "GS_SEQUENCER_ADDRESS"

cd "$OPTIMISM_DIR"/packages/contracts-bedrock

# Remove old generated internal-opstack-compose.json deploy config
rm -f ./deploy-config/internal-opstack-compose.json

# Check if deploy-config.json exists
if [ -f "/app/data/configurations/deploy-config.json" ]; then
  # Populate deploy-config.json with env variables
  echo "Populating deploy-config.json with env variables..."
  # NOTE: scripts/Deploy.s.sol:Deploy expects the deploy-config.json file to be in $OPTIMISM_DIR/packages/contracts-bedrock/deploy-config/
  envsubst < /app/data/configurations/deploy-config.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/internal-opstack-compose.json
elif [ -f "./deploy-config/$DEPLOYMENT_CONTEXT.json" ]; then
  # Populate deploy-config.json with env variables
  echo "Populating deploy-config.json with env variables..."
  # NOTE: scripts/Deploy.s.sol:Deploy expects the deploy-config.json file to be in $OPTIMISM_DIR/packages/contracts-bedrock/deploy-config/
  envsubst < ./deploy-config/$DEPLOYMENT_CONTEXT.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/internal-opstack-compose.json
else
  # If deploy-config.json does not exist, use config.sh to generate it
  echo "Generating deploy-config.json..."

  ./scripts/getting-started/config.sh
  mv ./deploy-config/getting-started.json ./deploy-config/internal-opstack-compose.json
fi

# Fix L1 and L2 Chain ID to the one set in the environment variable
export BATCH_INBOX_ADDRESS_TEMP=$(openssl rand -hex 32 | head -c 40)
jq \
  --argjson l1ChainID $L1_CHAIN_ID \
  --argjson l2ChainID $L2_CHAIN_ID \
  --arg batchInboxAddress "0x$BATCH_INBOX_ADDRESS_TEMP" \
  '.l1ChainID = $l1ChainID | .l2ChainID = $l2ChainID | .batchInboxAddress = $batchInboxAddress' \
  ./deploy-config/internal-opstack-compose.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/internal-opstack-compose.json

# Merge deploy override
if [ -f /app/data/configurations/deploy-override.json ]; then
  jq -s '.[0] * .[1]' ./deploy-config/internal-opstack-compose.json /app/data/configurations/deploy-override.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/internal-opstack-compose.json
fi

# Show deployment config for better debuggability
cat ./deploy-config/internal-opstack-compose.json

# Generate IMPL_SALT
if [ -z "$IMPL_SALT" ]; then
  export IMPL_SALT=$(sha256sum ./deploy-config/internal-opstack-compose.json | cut -d ' ' -f1)
fi

# If not deployed
if [ ! -f /app/data/deployments/.deploy ]; then
  # Set deployment context to internal
  export DEPLOYMENT_CONTEXT=internal-opstack-compose

  export DEPLOY_CONFIG_PATH=deploy-config/internal-opstack-compose.json
  mkdir -p deployments
  mkdir deployments/internal-opstack-compose
  export DEPLOYMENT_OUTFILE="$OPTIMISM_DIR"/packages/contracts-bedrock/deployments/"$DEPLOYMENT_CONTEXT"/.deploy

  # Deploy the L1 contracts
  forge script scripts/Deploy.s.sol:Deploy --private-key "$DEPLOYER_PRIVATE_KEY" --broadcast --rpc-url "$L1_RPC_URL"

  # Save the deployment address
  cp -r "$OPTIMISM_DIR"/packages/contracts-bedrock/deployments/"$DEPLOYMENT_CONTEXT"/. /app/data/deployments/

  # Copy deploy-config.json to the configurations volume
  cp ./deploy-config/internal-opstack-compose.json "$CONFIG_PATH"/deploy-config.json
fi

export CONTRACT_ADDRESSES_PATH=/app/data/deployments/.deploy
export STATE_DUMP_PATH=/app/data/deployments/allocs.json
forge script scripts/L2Genesis.s.sol:L2Genesis --chain-id $L2_CHAIN_ID  --sig 'runWithAllUpgrades()' --private-key $DEPLOYER_PRIVATE_KEY

# Generate the L2 config files
cd "$OPTIMISM_DIR"/op-node
go run cmd/main.go genesis l2 \
  --deploy-config "$CONFIG_PATH"/deploy-config.json \
  --l1-deployments "/app/data/deployments/.deploy" \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc "$L1_RPC_URL" \
  --l2-allocs /app/data/deployments/allocs.json
cp genesis.json "$CONFIG_PATH"/
cp rollup.json "$CONFIG_PATH"/

# Reset repository for cleanup
cd "$OPTIMISM_DIR"
git reset HEAD --hard

exec "$@"
