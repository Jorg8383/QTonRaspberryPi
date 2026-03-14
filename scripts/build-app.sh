#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-qt-app-image:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-qt-app-extract}"
APP_DIR="${APP_DIR:-project}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
APP_BINARY_NAME="${APP_BINARY_NAME:-HelloQt6}"
OUTPUT_DIR="${OUTPUT_DIR:-artifacts}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOST_OUTPUT_DIR="${ROOT_DIR}/${OUTPUT_DIR}"
APP_BINARY_PATH="/build/app/${APP_BINARY_NAME}"

cleanup() {
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed or not in PATH"
    exit 1
fi

if [[ ! -f "${ROOT_DIR}/Dockerfile.app" ]]; then
    echo "Error: ${ROOT_DIR}/Dockerfile.app does not exist."
    exit 1
fi

if [[ ! -d "${ROOT_DIR}/${APP_DIR}" ]]; then
    echo "Error: ${ROOT_DIR}/${APP_DIR} does not exist."
    exit 1
fi

# ------------------------------------------------------------
# Build app image and extract the binary
# ------------------------------------------------------------

mkdir -p "${HOST_OUTPUT_DIR}"

echo "==> Building app image: ${IMAGE_NAME}"
echo "==> APP_DIR=${APP_DIR}"
echo "==> BUILD_TYPE=${BUILD_TYPE}"

docker build \
  -f "${ROOT_DIR}/Dockerfile.app" \
  -t "${IMAGE_NAME}" \
  --build-arg APP_DIR="${APP_DIR}" \
  --build-arg BUILD_TYPE="${BUILD_TYPE}" \
  "${ROOT_DIR}"

echo "==> Extracting app binary: ${APP_BINARY_NAME}"

docker create --name "${CONTAINER_NAME}" "${IMAGE_NAME}" >/dev/null
docker cp "${CONTAINER_NAME}:${APP_BINARY_PATH}" "${HOST_OUTPUT_DIR}/${APP_BINARY_NAME}"

echo "==> App successfully compiled: ${HOST_OUTPUT_DIR}/${APP_BINARY_NAME}"