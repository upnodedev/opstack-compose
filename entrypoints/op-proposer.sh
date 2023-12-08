#!/bin/sh

$BIN_DIR/op-proposer \
  --poll-interval=12s \
  --rpc.port=8560 \
  --rollup-rpc=http://op-node:8547 \
  --l2oo-address=$(cat $DEPLOYMENT_DIR/L2OutputOracleProxy.json | jq -r .address) \
  --private-key=$GS_PROPOSER_PRIVATE_KEY \
  --l1-eth-rpc=$L1_RPC_URL \
  $OP_PROPOSER_EXTRA_FLAGS
