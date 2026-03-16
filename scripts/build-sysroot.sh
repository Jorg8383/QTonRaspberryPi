#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-qt-sysroot:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-qt-sysroot-extract}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ------------------------------------------------------------
# Delete docker container on exit
# ------------------------------------------------------------
cleanup() {
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------

if [[ ! -f "${ROOT_DIR}/Dockerfile.sysroot" ]]; then
    echo "Error: ${ROOT_DIR}/Dockerfile.sysroot not found"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker is not installed or not in PATH"
    exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: docker buildx is not available"
    echo "Install Docker Buildx or update Docker"
    exit 1
fi

if ! docker buildx inspect --bootstrap >/dev/null 2>&1; then
    echo "Error: docker buildx builder not initialized"
    echo "Run: docker buildx create --use --name qtbuilder"
    exit 1
fi

echo "==> Preflight checks passed"

# ------------------------------------------------------------
# Build ARM64 sysroot image
# ------------------------------------------------------------

echo "==> Building ARM64 sysroot image: ${IMAGE_NAME}"

docker buildx build \
  --platform linux/arm64 \
  --load \
  -f "${ROOT_DIR}/Dockerfile.sysroot" \
  -t "${IMAGE_NAME}" \
  "${ROOT_DIR}"

# ------------------------------------------------------------
# Extract rasp.tar.gz
# ------------------------------------------------------------

echo "==> Extracting rasp.tar.gz from ${IMAGE_NAME}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker create --name "${CONTAINER_NAME}" "${IMAGE_NAME}" >/dev/null

if ! docker cp "${CONTAINER_NAME}:/build/rasp.tar.gz" "${ROOT_DIR}/rasp.tar.gz"; then
    echo "Error: /build/rasp.tar.gz not found in image ${IMAGE_NAME}"
    exit 1
fi

echo "==> Sysroot tarball extracted: ${ROOT_DIR}/rasp.tar.gz"
