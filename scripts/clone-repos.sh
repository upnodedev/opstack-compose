#!/bin/bash

# Function to clear and clone a repository
clone_repo() {
  local repo_url=$1
  local branch_or_commit=$2
  local dest_dir=$3

  # Clear the existing directory contents if it is a git repository
  if [ -d "$dest_dir/.git" ]; then
    echo "Clearing existing repository in $dest_dir"
    # Remove all contents including hidden files and directories
    rm -rf "$dest_dir"/{,.[!.],..?}*
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
