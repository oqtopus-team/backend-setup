#!/bin/bash

# Ensure the script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Error: This script must be run with bash."
  echo "Usage: bash install.sh"
  exit 1
fi

set -euo pipefail

# --- Prerequisites Validation ---
echo "Checking prerequisites..."

check_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: $1 is not installed. Please install it before running this script."
    exit 1
  fi
}

check_tool git
check_tool docker
check_tool make

# Check for Docker Buildx plugin
if ! docker buildx version >/dev/null 2>&1; then
  echo "Error: docker-buildx-plugin is not installed."
  echo "See: https://docs.docker.com/build/install-buildx/"
  exit 1
fi

# --- Directory Preparation ---
echo "Creating directories..."

# Create logs directories
mkdir -p logs/{core,sse_engine,mitigator,estimator,combiner,tranqu-server,device-gateway}

# Create work directories
mkdir -p sse_work

# --- Repository Setup ---
echo "Cloning repositories..."

# Function to setup repository with sparse-checkout using subshell for safety
setup_repo_sparse() {
  local dir=$1
  local branch=$2
  local sparse_path=$3
  local repo_url="https://github.com/oqtopus-team/oqtopus-engine.git"

  if [ ! -d "$dir" ]; then
    echo "Setting up $dir..."
    # Using subshell () to ensure we always return to the original directory
    (
      git clone -b "$branch" --filter=blob:none --no-checkout "$repo_url" "$dir"
      cd "$dir"
      git sparse-checkout set "$sparse_path"
      git checkout
    )
  else
    echo "Directory $dir already exists. Skipping clone."
  fi
}

# Setup services from oqtopus-engine repository
setup_repo_sparse "core" "develop" "core"
setup_repo_sparse "sse_engine" "develop" "core"
setup_repo_sparse "mitigator" "develop" "mitigator"
setup_repo_sparse "estimator" "develop" "estimator"
setup_repo_sparse "combiner" "develop" "combiner"
setup_repo_sparse "sse_runtime" "develop" "sse_runtime"

# Setup other independent repositories
if [ ! -d "tranqu-server" ]; then
  git clone -b main https://github.com/oqtopus-team/tranqu-server.git
fi

if [ ! -d "device-gateway" ]; then
  git clone -b develop https://github.com/oqtopus-team/device-gateway.git
fi

echo "Installation completed successfully."
