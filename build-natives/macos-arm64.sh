#!/bin/sh
# Build and stage arm64 macOS shared libraries for zlib and libspng.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPNG_SRC="${1:-$ROOT/build/libspng-0.7.4}"
ZLIB_SRC="${2:-$ROOT/build/zlib-1.3.2}"
PREFIX="$ROOT/build/prefix-macos-arm64"
ZBUILD="$ROOT/build/zlib-build-macos-arm64"
SBUILD="$ROOT/build/libspng-build-macos-arm64"
DEST="$ROOT/natives/src/main/resources/libspng-natives/macos-arm64"

cmake -S "$ZLIB_SRC" -B "$ZBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DZLIB_BUILD_SHARED=ON \
  -DZLIB_BUILD_STATIC=OFF \
  -DZLIB_BUILD_TESTING=OFF
ninja -C "$ZBUILD" install

cmake -S "$SPNG_SRC" -B "$SBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DZLIB_ROOT="$PREFIX" \
  -DZLIB_LIBRARY="$PREFIX/lib/libz.dylib" \
  -DZLIB_INCLUDE_DIR="$PREFIX/include" \
  -DSPNG_SHARED=ON \
  -DSPNG_STATIC=OFF \
  -DBUILD_EXAMPLES=OFF
ninja -C "$SBUILD" install

rm -rf "$DEST"
mkdir -p "$DEST"

ZLIB_REAL="$(find "$PREFIX/lib" -type f -name 'libz.*.dylib' | sort | tail -1)"
SPNG_REAL="$(find "$PREFIX/lib" -type f -name 'libspng.dylib' | head -1)"
[ -n "$ZLIB_REAL" ] && [ -n "$SPNG_REAL" ] || { echo "built libraries not found"; exit 1; }

ZLIB_NAME="libz.1.dylib"
SPNG_NAME="libspng.dylib"
cp "$ZLIB_REAL" "$DEST/$ZLIB_NAME"
cp "$SPNG_REAL" "$DEST/$SPNG_NAME"
chmod 644 "$DEST/$ZLIB_NAME" "$DEST/$SPNG_NAME"
install_name_tool -id "@loader_path/$ZLIB_NAME" "$DEST/$ZLIB_NAME"
install_name_tool -id "@loader_path/$SPNG_NAME" "$DEST/$SPNG_NAME"
ZLIB_DEP="$(otool -L "$DEST/$SPNG_NAME" | awk '/libz\./ {print $1; exit}')"
[ -n "$ZLIB_DEP" ] || { echo "libspng has no zlib dependency"; exit 1; }
install_name_tool -change "$ZLIB_DEP" "@loader_path/$ZLIB_NAME" "$DEST/$SPNG_NAME"
printf '%s\n%s\n' "$ZLIB_NAME" "$SPNG_NAME" > "$DEST/manifest.txt"

cp "$SPNG_SRC/LICENSE" "$DEST/LICENSE-libspng.txt"
cp "$ROOT/third-party/LICENSE-libpng-2.0.txt" "$DEST/LICENSE-libpng-2.0.txt"
cp "$ZLIB_SRC/LICENSE" "$DEST/LICENSE-zlib.txt"
{
  echo "libspng 0.7.4"
  echo "zlib 1.3.2"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(uname -sm)"
  echo "sources: https://github.com/randy408/libspng and https://github.com/madler/zlib (unmodified)"
  echo "licenses: BSD-2-Clause and libpng-2.0 (libspng); zlib License (zlib)"
  echo "cmake flags: Release, shared libraries, arm64, optimizations enabled"
} > "$DEST/BUILD-INFO.txt"

if otool -L "$DEST/$SPNG_NAME" | grep -F "$PREFIX"; then
  echo "ERROR: build-prefix dependency survived"; exit 1
fi
file "$DEST/$ZLIB_NAME" "$DEST/$SPNG_NAME" | grep -q 'arm64' \
  || { echo "ERROR: libraries are not arm64"; exit 1; }
echo "staged:"
ls -la "$DEST"
