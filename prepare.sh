#!/bin/bash

# Ensure script stops on first error
set -e

# Clone the repositories
/app/clone-repos.sh

# Setting an environment variable for deployment
export IMPL_SALT=$(openssl rand -hex 32)

# Build the Optimism Monorepo
cd /app/data/optimism
pnpm install
make op-node op-batcher op-proposer
pnpm build

# Build op-geth
cd /app/data/op-geth
make geth

# Configure network
cd /app/data/optimism/packages/contracts-bedrock
./scripts/getting-started/config.sh

# Deploy the L1 contracts
forge script scripts/Deploy.s.sol:Deploy --private-key $GS_ADMIN_PRIVATE_KEY --broadcast --rpc-url $L1_RPC_URL
forge script scripts/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $L1_RPC_URL

cp -r /app/data/optimism/packages/contracts-bedrock/deployments/getting-started /app/data/deployments

# Generate the L2 config files
cd /app/data/optimism/op-node
go run cmd/main.go genesis l2 \
  --deploy-config ../packages/contracts-bedrock/deploy-config/getting-started.json \
  --deployment-dir ../packages/contracts-bedrock/deployments/getting-started/ \
  --outfile.l2 genesis.json \
  --outfile.rollup rollup.json \
  --l1-rpc $L1_RPC_URL
openssl rand -hex 32 > jwt.txt
cp genesis.json /app/data/op-geth
cp jwt.txt /app/data/op-geth

# Initialize op-geth
cd /app/data/op-geth
mkdir datadir
build/bin/geth init --datadir=datadir genesis.json

exec "$@"
