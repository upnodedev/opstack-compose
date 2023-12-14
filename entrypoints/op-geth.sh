#!/bin/sh

# Initialize op-geth if datadir is empty
if [ -d "$DATADIR_DIR" ] && [ -z "$(ls -A $DATADIR_DIR)" ]; then
  echo "Initializing op-geth as $DATADIR_DIR is empty..."

  # Creating password file
  echo "$PASSWORD" > "$DATADIR_DIR/password"

  # Creating block signer key file and importing it
  echo "$SEQUENCER_PRIVATE_KEY" > "$DATADIR_DIR/block-signer-key"
  $BIN_DIR/geth account import --datadir="$DATADIR_DIR" --password="$DATADIR_DIR/password" "$DATADIR_DIR/block-signer-key"

  # Initialize with genesis block
  $BIN_DIR/geth init --datadir=$DATADIR_DIR $CONFIG_PATH/genesis.json
fi

$BIN_DIR/geth
