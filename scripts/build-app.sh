#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-qtcrossbuild:latest}"
IMAGE_NAME="${IMAGE_NAME:-qt-app-image:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-qt-app-extract}"
# Change the default project directory as required
APP_DIR="${APP_DIR:-project}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-artifacts}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOST_OUTPUT_DIR="${ROOT_DIR}/${OUTPUT_DIR}"
# Change the default app binary name as required
APP_BINARY_NAME="${APP_BINARY_NAME:-HelloQt6}"
APP_BINARY_PATH="/build/app/${APP_BINARY_NAME}"
QT_PI_BINARY_NAME="qt-pi-binaries.tar.gz"
QT_PI_BINARY_PATH="/build/"
QT_PI_OPENCV_BINARY_NAME="opencv-binaries.tar.gz"

# ------------------------------------------------------------
# Clean up on exit
# ------------------------------------------------------------
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

if ! docker image inspect "${BASE_IMAGE}" >/dev/null 2>&1; then
    echo "Error: base image ${BASE_IMAGE} not found."
    echo "Run build-sdk-image.sh first."
    exit 1
fi

if [[ ! -d "${ROOT_DIR}/${APP_DIR}" ]]; then
    echo "Error: ${ROOT_DIR}/${APP_DIR} does not exist."
    exit 1
fi

# ------------------------------------------------------------
# Build app image and extract application/runtime artifacts
# ------------------------------------------------------------

mkdir -p "${HOST_OUTPUT_DIR}"

echo "==> Building app image: ${IMAGE_NAME}"
echo "==> APP_DIR=${APP_DIR}"
echo "==> BUILD_TYPE=${BUILD_TYPE}"
echo "==> APP_BINARY_NAME=${APP_BINARY_NAME}"

docker build \
  -f "${ROOT_DIR}/Dockerfile.app" \
  -t "${IMAGE_NAME}" \
  --build-arg APP_DIR="${APP_DIR}" \
  --build-arg BUILD_TYPE="${BUILD_TYPE}" \
  "${ROOT_DIR}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker create --name "${CONTAINER_NAME}" "${IMAGE_NAME}" >/dev/null

echo "==> Extracting app binary: ${APP_BINARY_NAME}"
docker cp "${CONTAINER_NAME}:${APP_BINARY_PATH}" "${HOST_OUTPUT_DIR}/${APP_BINARY_NAME}"

echo "==> Extracting Qt binaries: ${QT_PI_BINARY_NAME}"
docker cp "${CONTAINER_NAME}:${QT_PI_BINARY_PATH}${QT_PI_BINARY_NAME}" "${HOST_OUTPUT_DIR}/${QT_PI_BINARY_NAME}"

echo "==> Extracting OpenCV binaries: ${QT_PI_OPENCV_BINARY_NAME}"
if ! docker cp "${CONTAINER_NAME}:${QT_PI_BINARY_PATH}${QT_PI_OPENCV_BINARY_NAME}" "${HOST_OUTPUT_DIR}/${QT_PI_OPENCV_BINARY_NAME}"; then
    echo "==> OpenCV binaries not found, skipping"
fi

# ------------------------------------------------------------
# Clean up to save disk space
# ------------------------------------------------------------

echo "==> Removing temporary container"
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

echo "==> Removing temporary app image"
docker rmi "${IMAGE_NAME}" >/dev/null 2>&1 || true

echo "==> Done. Binary available at: ${HOST_OUTPUT_DIR}/${APP_BINARY_NAME}"