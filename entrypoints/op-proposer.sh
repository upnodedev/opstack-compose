#!/bin/sh

# Check if OP_PROPOSER_L2OO_ADDRESS environment variable is set
if [ -z "$OP_PROPOSER_L2OO_ADDRESS" ]; then
  # If not set, use the address from the $DEPLOYMENT_DIR
  OP_PROPOSER_L2OO_ADDRESS=$(cat $DEPLOYMENT_DIR/L2OutputOracleProxy.json | jq -r .address)
fi

$BIN_DIR/op-proposer
