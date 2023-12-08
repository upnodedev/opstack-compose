#!/bin/sh

$BIN_DIR/op-node \
  --l2=http://op-geth:8551 \
  --l2.jwt-secret=$CONFIG_PATH/jwt.txt \
  --sequencer.enabled \
  --sequencer.l1-confs=5 \
  --verifier.l1-confs=4 \
  --rollup.config=$CONFIG_PATH/rollup.json \
  --rpc.addr=0.0.0.0 \
  --rpc.port=8547 \
  --p2p.disable \
  --rpc.enable-admin \
  --p2p.sequencer.key=$GS_SEQUENCER_PRIVATE_KEY \
  --l1=$L1_RPC_URL \
  --l1.rpckind=$L1_RPC_KIND \
  $OP_NODE_EXTRA_FLAGS
