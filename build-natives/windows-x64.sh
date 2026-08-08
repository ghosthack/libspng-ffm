#!/bin/sh
# Build and stage x86-64 Windows DLLs from an MSYS2 MINGW64 shell.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPNG_SRC="${1:-$ROOT/build/libspng-0.7.4}"
ZLIB_SRC="${2:-$ROOT/build/zlib-1.3.2}"
PREFIX="$ROOT/build/prefix-windows-x64"
ZBUILD="$ROOT/build/zlib-build-windows-x64"
SBUILD="$ROOT/build/libspng-build-windows-x64"
DEST="$ROOT/natives/src/main/resources/libspng-natives/windows-x64"

cmake -S "$ZLIB_SRC" -B "$ZBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DZLIB_BUILD_SHARED=ON -DZLIB_BUILD_STATIC=OFF -DZLIB_BUILD_TESTING=OFF
ninja -C "$ZBUILD" install

ZLIB_IMPLIB="$(find "$PREFIX/lib" -type f \( -name '*z*.dll.a' -o -name '*z*.a' \) | head -1)"
[ -n "$ZLIB_IMPLIB" ] || { echo "zlib import library not found"; exit 1; }
cmake -S "$SPNG_SRC" -B "$SBUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib \
  -DZLIB_ROOT="$PREFIX" -DZLIB_LIBRARY="$ZLIB_IMPLIB" -DZLIB_INCLUDE_DIR="$PREFIX/include" \
  -DSPNG_SHARED=ON -DSPNG_STATIC=OFF -DBUILD_EXAMPLES=OFF
ninja -C "$SBUILD" install

rm -rf "$DEST"
mkdir -p "$DEST"
ZLIB_DLL="$(find "$PREFIX/bin" -type f -iname '*z*.dll' | head -1)"
SPNG_DLL="$(find "$PREFIX/bin" -type f -iname '*spng*.dll' | head -1)"
[ -n "$ZLIB_DLL" ] && [ -n "$SPNG_DLL" ] || { echo "built DLLs not found"; exit 1; }
cp "$ZLIB_DLL" "$DEST/$(basename "$ZLIB_DLL")"
cp "$SPNG_DLL" "$DEST/$(basename "$SPNG_DLL")"
chmod 644 "$DEST"/*.dll
printf '%s\n%s\n' "$(basename "$ZLIB_DLL")" "$(basename "$SPNG_DLL")" > "$DEST/manifest.txt"

cp "$SPNG_SRC/LICENSE" "$DEST/LICENSE-libspng.txt"
cp "$ROOT/third-party/LICENSE-libpng-2.0.txt" "$DEST/LICENSE-libpng-2.0.txt"
cp "$ZLIB_SRC/LICENSE" "$DEST/LICENSE-zlib.txt"
{
  echo "libspng 0.7.4"
  echo "zlib 1.3.2"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) in MSYS2 MINGW64"
  echo "sources: https://github.com/randy408/libspng and https://github.com/madler/zlib (unmodified)"
  echo "licenses: BSD-2-Clause and libpng-2.0 (libspng); zlib License (zlib)"
  echo "cmake flags: Release, shared libraries, x86-64, optimizations enabled"
} > "$DEST/BUILD-INFO.txt"

echo "staged:"
ls -la "$DEST"
