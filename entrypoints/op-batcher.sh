#!/bin/sh

# Check if OP_BATCHER_PRIVATE_KEY environment variable is set
if [ -z "$OP_BATCHER_PRIVATE_KEY" ]; then
  echo "OP_BATCHER_PRIVATE_KEY are missing, fetching from AWS Secrets Manager..."
  secrets=$(aws secretsmanager get-secret-value --secret-id $AWS_SECRET_ARN | jq '.SecretString | fromjson')

  OP_BATCHER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.BATCHER_PRIVATE_KEY')"

  export OP_BATCHER_PRIVATE_KEY
fi

exec $BIN_DIR/op-batcher
