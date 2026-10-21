#!/usr/bin/env bash
# Builds SDL3 from the release source as a static library into vendor/linux-x64/, which
# linc/linc_sdl3.xml links on Linux x64.
set -euo pipefail

VERSION=3.4.18
SHA256=9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/.build"
PREFIX="$HERE/vendor/linux-x64"
ARCHIVE="$WORK/download/SDL3-$VERSION.tar.gz"

mkdir -p "$WORK/download"
if [ ! -f "$ARCHIVE" ]; then
  curl -fsSL -o "$ARCHIVE" "https://github.com/libsdl-org/SDL/releases/download/release-$VERSION/SDL3-$VERSION.tar.gz"
fi
echo "$SHA256  $ARCHIVE" | sha256sum -c -

if [ ! -d "$WORK/SDL3-$VERSION" ]; then
  tar xzf "$ARCHIVE" -C "$WORK"
fi

cmake -S "$WORK/SDL3-$VERSION" -B "$WORK/build-linux-x64" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DSDL_TEST_LIBRARY=OFF \
  -DSDL_TESTS=OFF \
  -DSDL_EXAMPLES=OFF \
  -DSDL_X11_XTEST=OFF  # SDL warps the mouse with XTest when it has it and falls back to XWarpPointer; off skips the libxtst headers
cmake --build "$WORK/build-linux-x64"
cmake --install "$WORK/build-linux-x64"
