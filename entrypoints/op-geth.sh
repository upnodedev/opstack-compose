#!/bin/sh

# Initialize op-geth if datadir is empty
if [ -d "$DATADIR_DIR" ] && [ -z "$(ls -A $DATADIR_DIR)" ]; then
  echo "Initializing op-geth as $DATADIR_DIR is empty..."
  $BIN_DIR/geth init --datadir=$DATADIR_DIR $CONFIG_PATH/genesis.json
fi

$BIN_DIR/geth
