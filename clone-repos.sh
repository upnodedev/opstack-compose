#!/bin/bash

# Function to clear and clone a repository
clone_repo() {
  local repo_url=$1
  local branch=$2
  local dest_dir=$3

  # Clear the existing directory contents if it is a git repository
  if [ -d "$dest_dir/.git" ]; then
    echo "Clearing existing repository in $dest_dir"
    # Remove all contents including hidden files and directories
    rm -rf "$dest_dir"/{,.[!.],..?}*
  else
    # Ensure the directory exists
    mkdir -p "$dest_dir"
  fi

  # Clone the repository
  echo "Cloning $repo_url (branch: $branch) into $dest_dir"
  git clone --branch "$branch" "$repo_url" "$dest_dir"
  echo "Cloning complete"
}

# Use environment variables if set, otherwise default to the official repositories
OPTIMISM_REPO=${OPTIMISM_REPO_URL:-https://github.com/ethereum-optimism/optimism.git}
OPTIMISM_BRANCH=${OPTIMISM_BRANCH_OR_COMMIT:-develop}

OP_GETH_REPO=${OP_GETH_REPO_URL:-https://github.com/ethereum-optimism/op-geth.git}
OP_GETH_BRANCH=${OP_GETH_BRANCH_OR_COMMIT:-optimism}

# Cloning repositories
clone_repo "$OPTIMISM_REPO" "$OPTIMISM_BRANCH" /app/data/optimism
clone_repo "$OP_GETH_REPO" "$OP_GETH_BRANCH" /app/data/op-geth

git config --global --add safe.directory '*'

exec "$@"
