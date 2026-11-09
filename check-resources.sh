#!/bin/bash
# Read-only checks; do not download packages, compile, or create a rootfs.
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "$0")")
ARCH=${ARCH:-arm64}
case "$ARCH" in
    arm|arm32) ARCH=armhf ;;
    armhf|arm64) ;;
    *) echo "Unsupported Debian architecture: $ARCH" >&2; exit 1 ;;
esac
(cd "$SCRIPT_DIR" && sha256sum --check --quiet bsp/SHA256SUMS)
for component in xserver libmali libdrm mpp rga2; do
    packages=("$SCRIPT_DIR/packages/$ARCH/$component/"*.deb)
    [[ -r "${packages[0]}" ]] || { echo "Missing Debian packages: $ARCH/$component" >&2; exit 1; }
    for package in "${packages[@]}"; do
        package_arch=$(dpkg-deb -f "$package" Architecture)
        [[ "$package_arch" == "$ARCH" || "$package_arch" == all ]] || {
            echo "Wrong package architecture ($package_arch): $package" >&2
            exit 1
        }
    done
done
echo "Debian local BSP, bundled firmware and core package checks passed ($ARCH)."
