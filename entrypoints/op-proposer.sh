#!/bin/sh

cd /app/data/optimism/op-proposer
./bin/op-proposer \
  --poll-interval=12s \
  --rpc.port=8560\
  --rollup-rpc=http://localhost:8547\
  --l2oo-address=$(cat ../packages/contracts-bedrock/deployments/getting-started/L2OutputOracleProxy.json | jq -r .address) \
  --private-key=$GS_PROPOSER_PRIVATE_KEY \
  --l1-eth-rpc=$L1_RPC_URL
