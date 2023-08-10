#!/bin/sh

op-node \
	--l2=http://op-geth:8551 \
	--l2.jwt-secret=/var/upnode/jwtsecret/jwt.txt \    
	--sequencer.enabled \
	--sequencer.l1-confs=3 \
	--verifier.l1-confs=3 \
	--rollup.config=/var/upnode/data/rollup.json \
	--rpc.addr=0.0.0.0 \
	--rpc.port=8547 \
	--p2p.disable \
	--rpc.enable-admin \
	--p2p.sequencer.key=$SEQ_KEY \
	--l1=$L1_RPC \
	--l1.rpckind=$RPC_KIND