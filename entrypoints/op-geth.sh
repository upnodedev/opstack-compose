#!/bin/sh

# Initialize op-geth if datadir is empty
if [ -d "$DATA_DIR" ] && [ -z "$(ls -A $DATA_DIR)" ]; then
  echo "Initializing op-geth as $DATA_DIR is empty..."
  $BIN_DIR/geth init --datadir=$DATA_DIR $CONFIG_PATH/genesis.json
fi

$BIN_DIR/geth \
  --datadir $DATA_DIR \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.api=web3,debug,eth,txpool,net,engine \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api=debug,eth,txpool,net,engine \
  --syncmode=full \
  --gcmode=archive \
  --nodiscover \
  --maxpeers=0 \
  --networkid=42069 \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=$CONFIG_PATH/jwt.txt \
  --rollup.disabletxpoolgossip=true \
  $OP_GETH_EXTRA_FLAGS
