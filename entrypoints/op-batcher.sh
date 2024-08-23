#!/bin/sh

# Check if SIGNER_PROXY environment variable is set to false
if [ "$SIGNER_PROXY" != "true" ]; then
  unset OP_BATCHER_SIGNER_ENDPOINT
  unset OP_BATCHER_SIGNER_TLS_CA
  unset OP_BATCHER_SIGNER_TLS_CERT
  unset OP_BATCHER_SIGNER_TLS_KEY
else
  # shellcheck disable=SC1091
  . /app/utils.sh

  batcher_address=$(get_address "$OP_BATCHER_SIGNER_ENDPOINT")
  if [ -z "$OP_BATCHER_SIGNER_ADDRESS" ]; then
    export OP_BATCHER_SIGNER_ADDRESS=$batcher_address
  elif [ "$OP_BATCHER_SIGNER_ADDRESS" != "$batcher_address" ]; then
    echo "Error: OP_BATCHER_SIGNER_ADDRESS does not match the fetched address."
    exit 1
  fi
fi

# Check if OP_BATCHER_PRIVATE_KEY environment variable is set
if [ -z "$OP_BATCHER_PRIVATE_KEY" ]; then
  echo "OP_BATCHER_PRIVATE_KEY are missing, fetching from AWS Secrets Manager..."
  secrets=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_ARN" | jq '.SecretString | fromjson')

  OP_BATCHER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.BATCHER_PRIVATE_KEY')"

  export OP_BATCHER_PRIVATE_KEY
fi

exec "$BIN_DIR"/op-batcher
