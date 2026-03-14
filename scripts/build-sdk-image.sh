#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-qtcrossbuild:latest}"
BUILD_OPENCV="${BUILD_OPENCV:-OFF}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed or not in PATH"
    exit 1
fi

if [[ ! -f "${ROOT_DIR}/Dockerfile.sdk" ]]; then
    echo "Error: ${ROOT_DIR}/Dockerfile.sdk does not exist."
    exit 1
fi

if [[ ! -f "${ROOT_DIR}/rasp.tar.gz" ]]; then
    echo "Error: ${ROOT_DIR}/rasp.tar.gz does not exist."
    echo "Run build-sysroot.sh first."
    exit 1
fi

if [[ "${BUILD_OPENCV}" != "ON" && "${BUILD_OPENCV}" != "OFF" ]]; then
    echo "Error: BUILD_OPENCV must be ON or OFF"
    exit 1
fi

# ------------------------------------------------------------
# Build Qt cross-compile SDK image
# ------------------------------------------------------------

echo "==> Building SDK image: ${IMAGE_NAME}"
echo "==> BUILD_OPENCV=${BUILD_OPENCV}"

docker build \
  -f "${ROOT_DIR}/Dockerfile.sdk" \
  -t "${IMAGE_NAME}" \
  --build-arg BUILD_OPENCV="${BUILD_OPENCV}" \
  "${ROOT_DIR}"

echo "==> SDK image build complete"