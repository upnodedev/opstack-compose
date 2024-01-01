#!/bin/sh

# Check if OP_PROPOSER_PRIVATE_KEY environment variable is set
if [ -z "$OP_PROPOSER_PRIVATE_KEY" ]; then
  echo "OP_PROPOSER_PRIVATE_KEY are missing, fetching from AWS Secrets Manager..."
  secrets=$(aws secretsmanager get-secret-value --secret-id $AWS_SECRET_ARN | jq '.SecretString | fromjson')

  OP_PROPOSER_PRIVATE_KEY="$(echo "${secrets}" | jq -r '.PROPOSER_PRIVATE_KEY')"

  export OP_PROPOSER_PRIVATE_KEY
fi

# Check if OP_PROPOSER_L2OO_ADDRESS environment variable is set
if [ -z "$OP_PROPOSER_L2OO_ADDRESS" ]; then
  # If not set, use the address from the $DEPLOYMENT_DIR
  OP_PROPOSER_L2OO_ADDRESS=$(cat $DEPLOYMENT_DIR/L2OutputOracleProxy.json | jq -r .address)
fi

exec $BIN_DIR/op-proposer
