#!/bin/bash
# Downloads the pinned llvm-mingw release into tools/llvm-mingw and verifies
# its SHA-256 checksum. Supports macOS and Linux hosts. To upgrade the
# toolchain, bump LLVM_MINGW_VERSION and refresh the checksums below from a
# trusted download.
#
# This is optional: if RETROPAD_LLVM_MINGW points at an llvm-mingw installation
# you already have, cmake/toolchain-x86_64-mingw.cmake uses that instead and
# nothing needs downloading.
set -euo pipefail

cd "$(dirname "$0")/.." # Ensure we run from the project root

LLVM_MINGW_VERSION="20260616"

case "$(uname -s)" in
    Darwin)
        ASSET="llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-macos-universal.tar.xz"
        SHA256="2cab02a2e964bd4aae981150a45985d07c657cfa8d244959eb9e2dcc5eedd7b1"
        ;;
    Linux)
        ASSET="llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-22.04-x86_64.tar.xz"
        SHA256="534b92e067b22a6b4441f48ae9240a3341b17825d04d577eab0cf85c44b4deda"
        ;;
    *)
        echo "Error: unsupported host OS $(uname -s)." >&2
        exit 1
        ;;
esac

URL="https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/${ASSET}"

echo "Downloading ${ASSET}..."
curl -fL -o "$ASSET" "$URL"

echo "Verifying checksum..."
if command -v sha256sum >/dev/null 2>&1; then
    echo "${SHA256}  ${ASSET}" | sha256sum -c -
else
    echo "${SHA256}  ${ASSET}" | shasum -a 256 -c -
fi

echo "Extracting ${ASSET}..."
rm -rf tools/llvm-mingw
mkdir -p tools
tar -xf "$ASSET" -C tools/

# Rename the extracted folder to 'llvm-mingw'
EXTRACTED_DIR=$(find tools -maxdepth 1 -name "llvm-mingw-*" -type d)
mv "$EXTRACTED_DIR" tools/llvm-mingw

rm "$ASSET"
echo "llvm-mingw ${LLVM_MINGW_VERSION} installed into tools/llvm-mingw."
