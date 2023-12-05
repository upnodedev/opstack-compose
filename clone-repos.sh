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

# Cloning repositories
clone_repo https://github.com/ethereum-optimism/optimism.git develop /app/data/optimism
clone_repo https://github.com/ethereum-optimism/op-geth.git optimism /app/data/op-geth

git config --global --add safe.directory /app/data/optimism
git config --global --add safe.directory /app/data/op-geth

exec "$@"
