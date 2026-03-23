#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Arguments
# ------------------------------------------------------------

QT_TARBALL="${1:?Missing Qt tarball path}"
QT_INSTALL_DIR="${2:?Missing Qt install directory}"
APP_REMOTE_DIR="${3:?Missing app remote directory}"
APP_BINARY_NAME="${4:?Missing app binary name}"

APP_BINARY_SRC="$(dirname "${QT_TARBALL}")/${APP_BINARY_NAME}"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

die() {
    echo "Error: $*" >&2
    exit 1
}

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------

[[ -f "${QT_TARBALL}" ]] || die "Qt tarball not found: ${QT_TARBALL}"
[[ -f "${APP_BINARY_SRC}" ]] || die "App binary not found: ${APP_BINARY_SRC}"

# ------------------------------------------------------------
# Remote setup
# ------------------------------------------------------------

echo "==> Creating Qt install directory"
sudo mkdir -p "${QT_INSTALL_DIR}"

echo "==> Extracting Qt runtime"
sudo tar -xzf "${QT_TARBALL}" -C "${QT_INSTALL_DIR}"

echo "==> Creating app directory"
mkdir -p "${APP_REMOTE_DIR}"

echo "==> Installing app binary"
cp -f "${APP_BINARY_SRC}" "${APP_REMOTE_DIR}/"
chmod +x "${APP_REMOTE_DIR}/${APP_BINARY_NAME}"

echo "==> Registering Qt libraries with dynamic linker"
echo "${QT_INSTALL_DIR}/lib" | sudo tee /etc/ld.so.conf.d/qt6.conf >/dev/null
sudo ldconfig

echo "==> Creating launcher script"
cat > "${APP_REMOTE_DIR}/run-app.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export LD_LIBRARY_PATH="${QT_INSTALL_DIR}/lib:\${LD_LIBRARY_PATH:-}"
exec "${APP_REMOTE_DIR}/${APP_BINARY_NAME}"
EOF

chmod +x "${APP_REMOTE_DIR}/run-app.sh"

echo "==> Deployment finished"
echo "Qt installed in: ${QT_INSTALL_DIR}"
echo "App installed in: ${APP_REMOTE_DIR}"
echo
echo "Start app with:"
echo "  ${APP_REMOTE_DIR}/run-app.sh"