#!/bin/sh

# Init geth
if [ ! -e "/var/upnode/checkpoints" ]; then
  geth init --datadir=/var/upnode/datadir /var/upnode/data/genesis.json
fi

geth \
  --datadir /var/upnode/datadir \
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
  --networkid=$CHAIN_ID \
  --authrpc.vhosts="*" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret=/var/upnode/jwtsecret/jwt.txt \
  --rollup.disabletxpoolgossip=true \
  --txlookuplimit=0