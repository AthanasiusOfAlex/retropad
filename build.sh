#!/bin/bash
# Configures and builds retropad for Windows on a macOS or Linux host, using
# the llvm-mingw toolchain described in cmake/toolchain-x86_64-mingw.cmake.
#
#   ./build.sh                      Build Debug and Release
#   ./build.sh --config Release     Build Release only
#   ./build.sh --clean              Wipe the build directories first
#
# --arch exists and accepts only x86_64 today. It is here so that adding
# aarch64 later is a matter of dropping in cmake/toolchain-aarch64-mingw.cmake
# and widening the list, with no change to how the script is invoked.
set -e

ARCH="x86_64"
CONFIG="all"
CLEAN=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --arch) ARCH="$2"; shift ;;
        --config) CONFIG="$2"; shift ;;
        --clean) CLEAN=1 ;;
        -h|--help)
            echo "usage: $0 [--arch x86_64] [--config Debug|Release|all] [--clean]"
            exit 0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)

build_config() {
    local target_arch=$1
    local target_config=$2
    local build_dir="$PROJECT_ROOT/build/${target_arch}-${target_config}"
    local toolchain="$PROJECT_ROOT/cmake/toolchain-${target_arch}-mingw.cmake"

    if [ ! -f "$toolchain" ]; then
        echo "No toolchain file for arch '$target_arch' ($toolchain)." >&2
        exit 1
    fi

    echo -e "\n>>> Building $target_arch ($target_config)..."

    if [ $CLEAN -eq 1 ] && [ -d "$build_dir" ]; then
        echo "Cleaning $build_dir..."
        rm -rf "$build_dir"
    fi

    mkdir -p "$build_dir"

    cmake -S "$PROJECT_ROOT" -B "$build_dir" \
          -DCMAKE_BUILD_TYPE="$target_config" \
          -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    cmake --build "$build_dir" -j
}

if [ "$CONFIG" = "all" ]; then
    CONFIGS=("Debug" "Release")
else
    CONFIGS=("$CONFIG")
fi

for c in "${CONFIGS[@]}"; do
    build_config "$ARCH" "$c"
done
