#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILD_OPENCV="${BUILD_OPENCV:-OFF}"
APP_DIR="${APP_DIR:-project}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
APP_BINARY_NAME="${APP_BINARY_NAME:-HelloQt6}"

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------
if [[ ! -x "${SCRIPT_DIR}/build-sysroot.sh" ]]; then
  echo "Error: ${SCRIPT_DIR}/build-sysroot.sh not found or not executable"
  exit 1
fi

if [[ ! -x "${SCRIPT_DIR}/build-sdk-image.sh" ]]; then
  echo "Error: ${SCRIPT_DIR}/build-sdk-image.sh not found or not executable"
  exit 1
fi

if [[ ! -x "${SCRIPT_DIR}/build-app.sh" ]]; then
  echo "Error: ${SCRIPT_DIR}/build-app.sh not found or not executable"
  exit 1
fi

echo "=============================================================="
echo " Stage 1: Build sysroot image and extract sysroot tar"
echo "=============================================================="
"${SCRIPT_DIR}/build-sysroot.sh"

echo
echo "=============================================================="
echo " Stage 2: Build SDK image"
echo "=============================================================="
BUILD_OPENCV="${BUILD_OPENCV}" "${SCRIPT_DIR}/build-sdk-image.sh"

echo
echo "=============================================================="
echo " Stage 3: Build app image and extract binary"
echo "=============================================================="
APP_DIR="${APP_DIR}" \
BUILD_TYPE="${BUILD_TYPE}" \
APP_BINARY_NAME="${APP_BINARY_NAME}" \
"${SCRIPT_DIR}/build-app.sh"

echo
echo "==> Full build finished successfully"