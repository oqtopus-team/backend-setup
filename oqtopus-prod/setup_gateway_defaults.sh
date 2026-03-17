#!/bin/bash

# Ensure the script is run with bash
if [ -z "${BASH_VERSION:-}" ]; then
  echo "Error: This script must be run with bash."
  echo "Usage: bash $0"
  exit 1
fi

set -euo pipefail

# Define file paths
CONFIG_FILE="device-gateway/config/config.yaml"
ENV_FILE="config/.env"
TOPOLOGY_FILE="device-gateway/config/device_topology_sim.json"

DEVICE_ID="${1:-qulacs}"
MAX_QUBITS=16

# Check if .env exists before proceeding
if [ ! -f "${ENV_FILE}" ]; then
  echo "ERROR: ${ENV_FILE} not found. Please run install.sh first."
  exit 1
fi

# Ensure target directory exists and copy example files
mkdir -p device-gateway/config/
cp -p device-gateway/config/example/config.yaml device-gateway/config/
cp -p device-gateway/config/example/device_topology_sim.json device-gateway/config/
cp -p device-gateway/config/example/device_status device-gateway/config/

# Read GATEWAY_ADDRESS from .env (Remove quotes)
GATEWAY_ADDRESS=$(grep '^GATEWAY_ADDRESS=' "${ENV_FILE}" | cut -d '=' -f2- | tr -d '"')

if [ -z "${GATEWAY_ADDRESS:-}" ]; then
  echo "ERROR: GATEWAY_ADDRESS not found in ${ENV_FILE}"
  exit 1
fi

# Portable sed function to support both Linux (GNU) and macOS (BSD)
replace_in_file() {
  local pattern=$1
  local file=$2
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS/BSD sed requires an empty string argument for -i
    sed -i '' -E "${pattern}" "${file}"
  else
    # Linux/GNU sed
    sed -i -E "${pattern}" "${file}"
  fi
}

# Replace values in configuration files
replace_in_file 's/^([[:space:]]*max_qubits:).*/\1 '"${MAX_QUBITS}"'/' "${CONFIG_FILE}"
replace_in_file "s|^([[:space:]]*address:).*|\1 \"${GATEWAY_ADDRESS}\"|" "${CONFIG_FILE}"
replace_in_file "s|^([[:space:]]*device_id:).*|\1 \"${DEVICE_ID}\"|" "${CONFIG_FILE}"
replace_in_file "s|^([[:space:]]*\"device_id\":[[:space:]]*\")[^\"]*(\")|\1${DEVICE_ID}\2|" "${TOPOLOGY_FILE}"

echo "Updated ${CONFIG_FILE}"
echo "  device_id  = ${DEVICE_ID}"
echo "  max_qubits = ${MAX_QUBITS}"
echo "  address    = ${GATEWAY_ADDRESS}"

echo "Updated ${TOPOLOGY_FILE}"
echo "  device_id  = ${DEVICE_ID}"
