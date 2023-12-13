#!/bin/bash

# Ensure script stops on first error
set -e

# Clone repositories if necessary
if [ ! -d "$OPTIMISM_DIR/.git" ] || [ ! -d "$OP_GETH_DIR/.git" ]; then
  /app/clone-repos.sh
fi

# Check and build binaries if at least one doesn't exist
if [ ! -f "$BIN_DIR/op-node" ] || [ ! -f "$BIN_DIR/op-batcher" ] || [ ! -f "$BIN_DIR/op-proposer" ] || [ ! -f "$BIN_DIR/geth" ]; then
  # Clear and clone a repositories
  /app/clone-repos.sh

  # Build op-node, op-batcher and op-proposer
  cd $OPTIMISM_DIR
  pnpm install
  make op-node op-batcher op-proposer
  pnpm build

  # Copy binaries to the bin volume
  cp -f $OPTIMISM_DIR/op-node/bin/op-node $BIN_DIR/
  cp -f $OPTIMISM_DIR/op-batcher/bin/op-batcher $BIN_DIR/
  cp -f $OPTIMISM_DIR/op-proposer/bin/op-proposer $BIN_DIR/

  # Build op-geth
  cd $OP_GETH_DIR
  make geth

  # Copy geth binary to the bin volume
  cp ./build/bin/geth $BIN_DIR/
fi

# Check if all or none of the private keys are provided
if [ -z "$BATCHER_PRIVATE_KEY" ] && [ -z "$PROPOSER_PRIVATE_KEY" ] && [ -z "$SEQUENCER_PRIVATE_KEY" ]; then
  echo "All private keys are missing, fetching from AWS Secrets Manager..."
  secrets=$(aws secretsmanager get-secret-value --secret-id $AWS_SECRET_ARN | jq '.SecretString | fromjson')

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

# Check if all required components exist
if [ -f "$CONFIG_PATH/deploy-config.json" ] && [ -f "$CONFIG_PATH/jwt.txt" ] && [ -f "$CONFIG_PATH/genesis.json" ] && [ -f "$CONFIG_PATH/rollup.json" ] && [ -d "$DEPLOYMENT_DIR" ]; then
  echo "All required components are present, skipping script."
  exec "$@"
  exit 0
fi

# Check if at least one required component exists but not all
if [ -f "$CONFIG_PATH/deploy-config.json" ] || [ -f "$CONFIG_PATH/jwt.txt" ] || [ -f "$CONFIG_PATH/genesis.json" ] || [ -f "$CONFIG_PATH/rollup.json" ] || [ -d "$DEPLOYMENT_DIR" ]; then
  echo "Error: Partial components are present, but not all. Exiting script."
  exit 1
fi

# If no components exist, continue with the script
echo "No required components are present, continuing script execution."

# Check if both L1_BLOCKHASH and L1_TIMESTAMP are set or unset
if [ -n "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ] || [ -z "$L1_BLOCKHASH" ] && [ -n "$L1_TIMESTAMP" ]; then
  echo "Error: Both L1_BLOCKHASH and L1_TIMESTAMP must be set or unset."
  exit 1
elif [ -z "$L1_BLOCKHASH" ] && [ -z "$L1_TIMESTAMP" ]; then
  # Fetch block details if both variables are unset
  echo "Fetching block details from L1_RPC_URL..."
  block=$(cast block finalized --rpc-url "$L1_RPC_URL")
  export L1_TIMESTAMP=$(echo "$block" | awk '/timestamp/ { print $2 }')
  export L1_BLOCKHASH=$(echo "$block" | awk '/hash/ { print $2 }')
fi

# Source the utils.sh file
source /app/utils.sh

# Derive addresses from private keys and check for conflicts
derive_and_check "ADMIN_PRIVATE_KEY" "GS_ADMIN_ADDRESS"
derive_and_check "BATCHER_PRIVATE_KEY" "GS_BATCHER_ADDRESS"
derive_and_check "PROPOSER_PRIVATE_KEY" "GS_PROPOSER_ADDRESS"
derive_and_check "SEQUENCER_PRIVATE_KEY" "GS_SEQUENCER_ADDRESS"

cd $OPTIMISM_DIR/packages/contracts-bedrock

# Check if the file ./deploy-config/$DEPLOYMENT_CONTEXT.json exists and the file "/app/deploy-config.json" does not exist
if [ -f "./deploy-config/$DEPLOYMENT_CONTEXT.json" ] && [ ! -f "/app/deploy-config.json" ]; then
  # If the condition is true, copy the file ./deploy-config/$DEPLOYMENT_CONTEXT.json to /app/deploy-config.json
  DEPLOY_CONFIG_CHECKSUM=$(md5sum "./deploy-config/$DEPLOYMENT_CONTEXT.json" | awk '{print $1}')
  if [ "$DEPLOY_CONFIG_CHECKSUM" == "cd4d5dd0b96826ca4c51716de6aad7e7" ]; then
    rm ./deploy-config/$DEPLOYMENT_CONTEXT.json
    if [ ! -f "./scripts/getting-started/config.sh" ]; then
      mkdir -p ./scripts/getting-started
      cp /app/getting-started-config.sh ./scripts/getting-started/config.sh
      chmod +x ./scripts/getting-started/config.sh
    fi
  else
    cp ./deploy-config/$DEPLOYMENT_CONTEXT.json /app/deploy-config.json
  fi
fi

# Check if deploy-config.json exists
if [ -f "/app/deploy-config.json" ]; then
  # Populate deploy-config.json with env variables
  echo "Populating deploy-config.json with env variables..."
  # NOTE: scripts/Deploy.s.sol:Deploy expects the deploy-config.json file to be in $OPTIMISM_DIR/packages/contracts-bedrock/deploy-config/
  envsubst < /app/deploy-config.json > /app/temp-deploy-config.json && mv /app/temp-deploy-config.json ./deploy-config/$DEPLOYMENT_CONTEXT.json
else
  # If deploy-config.json does not exist, use config.sh to generate it
  echo "Generating deploy-config.json..."
  ./scripts/getting-started/config.sh
  if [ "./deploy-config/getting-started.json" != "./deploy-config/$DEPLOYMENT_CONTEXT.json" ]; then
    mv ./deploy-config/getting-started.json ./deploy-config/$DEPLOYMENT_CONTEXT.json
  fi
fi

# Copy deploy-config.json to the configurations volume
cp ./deploy-config/$DEPLOYMENT_CONTEXT.json $CONFIG_PATH/deploy-config.json

# Setting an environment variable for deployment
export IMPL_SALT=$(openssl rand -hex 32)

# Deploy the L1 contracts
forge script scripts/Deploy.s.sol:Deploy --private-key $DEPLOYER_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL
forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $L1_RPC_URL

cp -r $OPTIMISM_DIR/packages/contracts-bedrock/deployments/$DEPLOYMENT_CONTEXT /app/data/deployments/

# Generate the L2 config files
cd $OPTIMISM_DIR/op-node
go run cmd/main.go genesis l2 \
  --deploy-config $CONFIG_PATH/deploy-config.json \
  --deployment-dir $DEPLOYMENT_DIR/ \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc $L1_RPC_URL
openssl rand -hex 32 > $CONFIG_PATH/jwt.txt
cp genesis.json $CONFIG_PATH/
cp rollup.json $CONFIG_PATH/

exec "$@"
