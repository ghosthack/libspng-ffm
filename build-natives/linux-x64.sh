#!/bin/sh
# Build and stage x86-64 Linux shared libraries for zlib and libspng.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPNG_SRC="${1:-$ROOT/build/libspng-0.7.4}"
ZLIB_SRC="${2:-$ROOT/build/zlib-1.3.2}"
PREFIX="$ROOT/build/prefix-linux-x64"
ZBUILD="$ROOT/build/zlib-build-linux-x64"
SBUILD="$ROOT/build/libspng-build-linux-x64"
DEST="$ROOT/natives/src/main/resources/libspng-natives/linux-x64"

cmake -S "$ZLIB_SRC" -B "$ZBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DZLIB_BUILD_SHARED=ON -DZLIB_BUILD_STATIC=OFF -DZLIB_BUILD_TESTING=OFF
ninja -C "$ZBUILD" install

cmake -S "$SPNG_SRC" -B "$SBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INSTALL_RPATH='$ORIGIN' \
  -DZLIB_ROOT="$PREFIX" -DZLIB_LIBRARY="$PREFIX/lib/libz.so" -DZLIB_INCLUDE_DIR="$PREFIX/include" \
  -DSPNG_SHARED=ON -DSPNG_STATIC=OFF -DBUILD_EXAMPLES=OFF
ninja -C "$SBUILD" install

rm -rf "$DEST"
mkdir -p "$DEST"
ZLIB_REAL="$(find "$PREFIX/lib" -type f -name 'libz.so.*' | sort | tail -1)"
SPNG_REAL="$(find "$PREFIX/lib" -type f -name 'libspng.so' | head -1)"
[ -n "$ZLIB_REAL" ] && [ -n "$SPNG_REAL" ] || { echo "built libraries not found"; exit 1; }
cp "$ZLIB_REAL" "$DEST/libz.so.1"
cp "$SPNG_REAL" "$DEST/libspng.so"
chmod 644 "$DEST/libz.so.1" "$DEST/libspng.so"
patchelf --set-soname libz.so.1 "$DEST/libz.so.1"
patchelf --set-soname libspng.so --set-rpath '$ORIGIN' "$DEST/libspng.so"
printf '%s\n%s\n' libz.so.1 libspng.so > "$DEST/manifest.txt"

cp "$SPNG_SRC/LICENSE" "$DEST/LICENSE-libspng.txt"
cp "$ROOT/third-party/LICENSE-libpng-2.0.txt" "$DEST/LICENSE-libpng-2.0.txt"
cp "$ZLIB_SRC/LICENSE" "$DEST/LICENSE-zlib.txt"
{
  echo "libspng 0.7.4"
  echo "zlib 1.3.2"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(uname -sm)"
  echo "sources: https://github.com/randy408/libspng and https://github.com/madler/zlib (unmodified)"
  echo "licenses: BSD-2-Clause and libpng-2.0 (libspng); zlib License (zlib)"
  echo "cmake flags: Release, shared libraries, x86-64, optimizations enabled"
} > "$DEST/BUILD-INFO.txt"

readelf -d "$DEST/libspng.so" | grep -q '\$ORIGIN' \
  || { echo "ERROR: libspng rpath is not relative"; exit 1; }
echo "staged:"
ls -la "$DEST"
