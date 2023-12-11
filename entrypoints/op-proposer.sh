#!/bin/sh

$BIN_DIR/op-proposer \
  --l2oo-address=$(cat $DEPLOYMENT_DIR/L2OutputOracleProxy.json | jq -r .address) \
