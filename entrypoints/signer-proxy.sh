#!/bin/bash

reqenv() {
  if [ -z "${!1}" ]; then
    echo "Error: environment variable '$1' is undefined"
    exit 1
  fi
}

reqenv "SIGNER_PROXY_MODE"
reqenv "OP_BATCHER_SIGNER_KEY_ID"
reqenv "OP_PROPOSER_SIGNER_KEY_ID"

exec signer-proxy "${SIGNER_PROXY_MODE}" serve
