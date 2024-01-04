#!/bin/sh

# Initialize op-geth if datadir is empty
if [ -d "$DATADIR_DIR" ] && [ -z "$(ls -A "$DATADIR_DIR")" ]; then
  echo "Initializing op-geth as $DATADIR_DIR is empty..."

  # Creating password file and block signer key file only if PASSWORD, GETH_PASSWORD is set and SEQUENCER_MODE is true
  if [ -n "$PASSWORD" ] && [ -n "$GETH_PASSWORD" ] && [ "$SEQUENCER_MODE" = "true" ]; then
    echo "$PASSWORD" > "$DATADIR_DIR/password"

    # Check if SEQUENCER_PRIVATE_KEY environment variable is set
    if [ -z "$SEQUENCER_PRIVATE_KEY" ]; then
      echo "SEQUENCER_PRIVATE_KEY are missing, fetching from AWS Secrets Manager..."
      secrets=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_ARN" | jq '.SecretString | fromjson')

      SEQUENCER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.SEQUENCER_PRIVATE_KEY')"

      export SEQUENCER_PRIVATE_KEY
    fi

    # Creating block signer key file and importing it
    echo "$SEQUENCER_PRIVATE_KEY" > "$DATADIR_DIR/block-signer-key"
    "$BIN_DIR"/geth account import --datadir="$DATADIR_DIR" --password="$DATADIR_DIR/password" "$DATADIR_DIR/block-signer-key"
  fi

  # Initialize with genesis block
  "$BIN_DIR"/geth init --datadir="$DATADIR_DIR" "$CONFIG_PATH"/genesis.json
fi

exec "$BIN_DIR"/geth
