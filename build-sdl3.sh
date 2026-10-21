#!/usr/bin/env bash
# Puts SDL 3.4.18 in vendor/, where linc/linc_sdl3.xml links it from.
#
#   ./build-sdl3.sh           builds a static library from the source into vendor/linux-x64/
#   ./build-sdl3.sh android   unpacks SDL's prebuilt Android package into vendor/android/: the headers,
#                             libSDL3.so for each CPU type, and SDL3.jar with SDL's Java classes
set -euo pipefail

VERSION=3.4.18
SOURCE_SHA256=9c75cf16330322c217dedd2e0609f1124f1b54b8633e763467b4684d0f4334a3
ANDROID_SHA256=e09e4d6593335d089ba124375e8b8abd0fd75173dffcd2c17012b45af121d4e9

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/.build"
TARGET="${1:-linux-x64}"

# Downloads a file from SDL's release once, and checks it every time.
download() {
  local file="$1" sha256="$2"
  mkdir -p "$WORK/download"
  if [ ! -f "$WORK/download/$file" ]; then
    curl -fsSL -o "$WORK/download/$file" "https://github.com/libsdl-org/SDL/releases/download/release-$VERSION/$file"
  fi
  echo "$sha256  $WORK/download/$file" | sha256sum -c -
}

case "$TARGET" in
  linux-x64)
    PREFIX="$HERE/vendor/linux-x64"
    download "SDL3-$VERSION.tar.gz" "$SOURCE_SHA256"
    if [ ! -d "$WORK/SDL3-$VERSION" ]; then
      tar xzf "$WORK/download/SDL3-$VERSION.tar.gz" -C "$WORK"
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
    ;;

  android)
    PREFIX="$HERE/vendor/android"
    download "SDL3-devel-$VERSION-android.zip" "$ANDROID_SHA256"
    rm -rf "$WORK/android" "$PREFIX"
    mkdir -p "$WORK/android/aar" "$PREFIX/lib"
    unzip -q "$WORK/download/SDL3-devel-$VERSION-android.zip" -d "$WORK/android"
    unzip -q "$WORK/android/SDL3-$VERSION.aar" -d "$WORK/android/aar"
    modules="$WORK/android/aar/prefab/modules"
    cp -r "$modules/SDL3-Headers/include" "$PREFIX/include"
    for dir in "$modules"/SDL3-shared/libs/android.*; do
      abi="${dir##*/android.}"
      mkdir -p "$PREFIX/lib/$abi"
      cp "$dir/libSDL3.so" "$PREFIX/lib/$abi/"
    done
    cp "$WORK/android/aar/classes.jar" "$PREFIX/SDL3.jar"
    echo "Unpacked SDL $VERSION for Android into $PREFIX"
    ;;

  *)
    echo "Unknown target '$TARGET': use linux-x64 (the default) or android." >&2
    exit 1
    ;;
esac
