#!/bin/bash

# Function to clear and clone a repository
clone_repo() {
  local repo_url=$1
  local branch_or_commit=$2
  local dest_dir=$3

  # Check if the repository is on the correct version
  if [ -d "$dest_dir/.git" ]; then
    echo "Checking repository version in $dest_dir"
    git -C "$dest_dir" fetch
    [ "$(git -C "$dest_dir" rev-parse HEAD)" != "$(git -C "$dest_dir" rev-parse $branch_or_commit)" ] && needs_update=true || needs_update=false

    if [ "$needs_update" = true ]; then
      echo "Version mismatch. Clearing binaries and existing repository..."
      # Add commands to remove binaries here
      rm -f "$BIN_DIR"/op-node "$BIN_DIR"/op-batcher "$BIN_DIR"/op-proposer "$BIN_DIR"/geth

      # Remove all contents including hidden files and directories
      rm -rf "$dest_dir"/{,.[!.],..?}*
    else
      echo "Repository in $dest_dir is already up to date."
      return
    fi
  fi

  # Clone the repository
  echo "Cloning $repo_url into $dest_dir"
  git clone "$repo_url" "$dest_dir"
  echo "Cloning complete"

  # Checkout to the specific branch or commit
  echo "Checking out to $branch_or_commit"
  git -C "$dest_dir" checkout "$branch_or_commit"
}

# Use environment variables if set, otherwise default to the official repositories
OPTIMISM_REPO=${OPTIMISM_REPO_URL:-https://github.com/ethereum-optimism/optimism.git}
OPTIMISM_BRANCH_OR_COMMIT=${OPTIMISM_BRANCH_OR_COMMIT:-develop}

OP_GETH_REPO=${OP_GETH_REPO_URL:-https://github.com/ethereum-optimism/op-geth.git}
OP_GETH_BRANCH_OR_COMMIT=${OP_GETH_BRANCH_OR_COMMIT:-optimism}

# Cloning repositories
clone_repo "$OPTIMISM_REPO" "$OPTIMISM_BRANCH_OR_COMMIT" $OPTIMISM_DIR
clone_repo "$OP_GETH_REPO" "$OP_GETH_BRANCH_OR_COMMIT" $OP_GETH_DIR

git config --global --add safe.directory '*'

exec "$@"
