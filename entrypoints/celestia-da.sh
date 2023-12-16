#!/bin/bash

# Variables for keyring and node store paths
KEYRING_PATH="/home/celestia/$DA_FOLDER_NAME/keys/keyring-test/$ACCNAME.info"
NODE_STORE="/home/celestia/$DA_FOLDER_NAME"
NODE_STORE_CONFIG_PATH="$NODE_STORE/config.toml"

# Check if keyring exists and recover key if it doesn't
if [ ! -f "$KEYRING_PATH" ]; then
  echo "Keyring not found or empty. Recovering key..."

  # Check if the mnemonic is provided
  if [ -z "$DA_KEYRING_MNEMONIC" ]; then
    echo "Error: Mnemonic not provided in DA_KEYRING_MNEMONIC"
    exit 1
  fi

  # Use the mnemonic to recover the key
  echo $DA_KEYRING_MNEMONIC | cel-key add $ACCNAME --recover --keyring-backend test --node.type light --keyring-dir $NODE_STORE/keys --p2p.network $DA_P2P_NETWORK
fi

# Check if the node store is initialized
if [ ! -f $NODE_STORE_CONFIG_PATH ]; then
  echo "Initializing Celestia Node Store as $NODE_STORE_PATH is missing..."
  celestia-da light init --p2p.network=$DA_P2P_NETWORK --node.store $NODE_STORE/
fi


# Start the Celestia node
celestia-da light start \
  --da.grpc.namespace=$DA_GRPC_NAMESPACE \
  --da.grpc.listen=0.0.0.0:26650 \
  --core.ip $DA_CORE_IP \
  --p2p.network=$DA_P2P_NETWORK \
  --keyring.accname=$ACCNAME \
  --gateway
