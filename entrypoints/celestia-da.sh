#!/bin/bash

# Check if keyring exists and recover key if it doesn't
if [ ! -f "$CELESTIA_KEYRING_PATH" ]; then
  echo "Keyring not found or empty. Recovering key..."

  # Check if the mnemonic is provided
  if [ -z "$DA_KEYRING_MNEMONIC" ]; then
    echo "Error: Mnemonic not provided in DA_KEYRING_MNEMONIC"
    exit 1
  fi

  # Use the mnemonic to recover the key
  echo $DA_KEYRING_MNEMONIC | cel-key add $ACCNAME --recover --keyring-backend test --node.type light --keyring-dir $CELESTIA_NODE_STORE/keys --p2p.network $DA_P2P_NETWORK
fi

# Check if the node store is initialized
if [ ! -f $CELESTIA_NODE_STORE_CONFIG_PATH ]; then
  echo "Initializing Celestia Node Store as $CELESTIA_NODE_STORE_CONFIG_PATH is missing..."
  celestia-da light init --p2p.network=$DA_P2P_NETWORK --node.store $CELESTIA_NODE_STORE/
fi

# Start the Celestia node
exec celestia-da light start \
  --da.grpc.namespace=$DA_GRPC_NAMESPACE \
  --da.grpc.listen=0.0.0.0:26650 \
  --core.ip $DA_CORE_IP \
  --p2p.network=$DA_P2P_NETWORK \
  --keyring.accname=$ACCNAME \
  --gateway
