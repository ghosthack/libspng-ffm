#!/bin/sh
# Generate JDK 22 FFM stubs for libspng's complete public API.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JX="${JEXTRACT:-$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract}"
PREFIX="${LIBSPNG_PREFIX:-$ROOT/build/prefix-macos-arm64}"
OUT="$ROOT/core/src/main/java"
PKG="io.github.ghosthack.libspngffm.spng"
SDK="$(xcrun --show-sdk-path)"

[ -x "$JX" ] || { echo "jextract not found at $JX (set JEXTRACT=)"; exit 1; }
[ -f "$PREFIX/include/spng.h" ] || { echo "run build-natives/macos-arm64.sh first"; exit 1; }
[ -f "$PREFIX/lib/libspng.dylib" ] || { echo "libspng.dylib not found under $PREFIX/lib"; exit 1; }

GEN_DIR="$OUT/$(echo "$PKG" | tr . /)"
rm -rf "$GEN_DIR"

set -- "$JX" --output "$OUT" -t "$PKG" \
  --header-class-name LibSpng \
  -I "$SDK/usr/include" \
  -I "$PREFIX/include" \
  -l ":$PREFIX/lib/libspng.dylib"

for symbol in \
  spng_ctx_new spng_ctx_new2 spng_ctx_free \
  spng_set_png_buffer spng_set_png_stream spng_set_png_file spng_get_png_buffer \
  spng_set_image_limits spng_get_image_limits \
  spng_set_chunk_limits spng_get_chunk_limits spng_set_crc_action \
  spng_set_option spng_get_option spng_decoded_image_size \
  spng_decode_image spng_decode_scanline spng_decode_row spng_decode_chunks \
  spng_get_row_info \
  spng_encode_image spng_encode_scanline spng_encode_row spng_encode_chunks \
  spng_get_ihdr spng_get_plte spng_get_trns \
  spng_get_chrm spng_get_chrm_int spng_get_gama spng_get_gama_int \
  spng_get_iccp spng_get_sbit spng_get_srgb spng_get_text \
  spng_get_bkgd spng_get_hist spng_get_phys spng_get_splt spng_get_time \
  spng_get_unknown_chunks spng_get_offs spng_get_exif \
  spng_set_ihdr spng_set_plte spng_set_trns \
  spng_set_chrm spng_set_chrm_int spng_set_gama spng_set_gama_int \
  spng_set_iccp spng_set_sbit spng_set_srgb spng_set_text \
  spng_set_bkgd spng_set_hist spng_set_phys spng_set_splt spng_set_time \
  spng_set_unknown_chunks spng_set_offs spng_set_exif \
  spng_strerror spng_version_string
do
  set -- "$@" --include-function "$symbol"
done

for symbol in \
  spng_ihdr spng_plte_entry spng_plte spng_trns spng_chrm_int spng_chrm \
  spng_iccp spng_sbit spng_text spng_bkgd spng_hist spng_phys \
  spng_splt_entry spng_splt spng_time spng_offs spng_exif spng_chunk \
  spng_unknown_chunk spng_alloc spng_row_info
do
  set -- "$@" --include-struct "$symbol"
done

for symbol in \
  spng_malloc_fn spng_realloc_fn spng_calloc_fn spng_free_fn \
  spng_ctx spng_read_fn spng_write_fn spng_rw_fn
do
  set -- "$@" --include-typedef "$symbol"
done

for symbol in \
  SPNG_VERSION_MAJOR SPNG_VERSION_MINOR SPNG_VERSION_PATCH \
  SPNG_IO_ERROR SPNG_IO_EOF SPNG_OK SPNG_EINVAL SPNG_EMEM SPNG_EOVERFLOW \
  SPNG_ESIGNATURE SPNG_EWIDTH SPNG_EHEIGHT SPNG_EUSER_WIDTH SPNG_EUSER_HEIGHT \
  SPNG_EBIT_DEPTH SPNG_ECOLOR_TYPE SPNG_ECOMPRESSION_METHOD SPNG_EFILTER_METHOD \
  SPNG_EINTERLACE_METHOD SPNG_EIHDR_SIZE SPNG_ENOIHDR SPNG_ECHUNK_POS \
  SPNG_ECHUNK_SIZE SPNG_ECHUNK_CRC SPNG_ECHUNK_TYPE SPNG_ECHUNK_UNKNOWN_CRITICAL \
  SPNG_EDUP_PLTE SPNG_EDUP_CHRM SPNG_EDUP_GAMA SPNG_EDUP_ICCP SPNG_EDUP_SBIT \
  SPNG_EDUP_SRGB SPNG_EDUP_BKGD SPNG_EDUP_HIST SPNG_EDUP_TRNS SPNG_EDUP_PHYS \
  SPNG_EDUP_TIME SPNG_EDUP_OFFS SPNG_EDUP_EXIF SPNG_ECHRM SPNG_EPLTE_IDX \
  SPNG_ETRNS_COLOR_TYPE SPNG_ETRNS_NO_PLTE SPNG_EGAMA SPNG_EICCP_NAME \
  SPNG_EICCP_COMPRESSION_METHOD SPNG_ESBIT SPNG_ESRGB SPNG_ETEXT \
  SPNG_ETEXT_KEYWORD SPNG_EZTXT SPNG_EZTXT_COMPRESSION_METHOD SPNG_EITXT \
  SPNG_EITXT_COMPRESSION_FLAG SPNG_EITXT_COMPRESSION_METHOD SPNG_EITXT_LANG_TAG \
  SPNG_EITXT_TRANSLATED_KEY SPNG_EBKGD_NO_PLTE SPNG_EBKGD_PLTE_IDX \
  SPNG_EHIST_NO_PLTE SPNG_EPHYS SPNG_ESPLT_NAME SPNG_ESPLT_DUP_NAME \
  SPNG_ESPLT_DEPTH SPNG_ETIME SPNG_EOFFS SPNG_EEXIF SPNG_EIDAT_TOO_SHORT \
  SPNG_EIDAT_STREAM SPNG_EZLIB SPNG_EFILTER SPNG_EBUFSIZ SPNG_EIO SPNG_EOF \
  SPNG_EBUF_SET SPNG_EBADSTATE SPNG_EFMT SPNG_EFLAGS SPNG_ECHUNKAVAIL \
  SPNG_ENCODE_ONLY SPNG_EOI SPNG_ENOPLTE SPNG_ECHUNK_LIMITS SPNG_EZLIB_INIT \
  SPNG_ECHUNK_STDLEN SPNG_EINTERNAL SPNG_ECTXTYPE SPNG_ENOSRC SPNG_ENODST \
  SPNG_EOPSTATE SPNG_ENOTFINAL \
  SPNG_TEXT SPNG_ZTXT SPNG_ITXT \
  SPNG_COLOR_TYPE_GRAYSCALE SPNG_COLOR_TYPE_TRUECOLOR SPNG_COLOR_TYPE_INDEXED \
  SPNG_COLOR_TYPE_GRAYSCALE_ALPHA SPNG_COLOR_TYPE_TRUECOLOR_ALPHA \
  SPNG_FILTER_NONE SPNG_FILTER_SUB SPNG_FILTER_UP SPNG_FILTER_AVERAGE SPNG_FILTER_PAETH \
  SPNG_DISABLE_FILTERING SPNG_FILTER_CHOICE_NONE SPNG_FILTER_CHOICE_SUB \
  SPNG_FILTER_CHOICE_UP SPNG_FILTER_CHOICE_AVG SPNG_FILTER_CHOICE_PAETH \
  SPNG_FILTER_CHOICE_ALL SPNG_INTERLACE_NONE SPNG_INTERLACE_ADAM7 \
  SPNG_FMT_RGBA8 SPNG_FMT_RGBA16 SPNG_FMT_RGB8 SPNG_FMT_GA8 SPNG_FMT_GA16 \
  SPNG_FMT_G8 SPNG_FMT_PNG SPNG_FMT_RAW SPNG_CTX_IGNORE_ADLER32 SPNG_CTX_ENCODER \
  SPNG_DECODE_USE_TRNS SPNG_DECODE_USE_GAMA SPNG_DECODE_USE_SBIT \
  SPNG_DECODE_TRNS SPNG_DECODE_GAMMA SPNG_DECODE_PROGRESSIVE \
  SPNG_CRC_ERROR SPNG_CRC_DISCARD SPNG_CRC_USE \
  SPNG_ENCODE_PROGRESSIVE SPNG_ENCODE_FINALIZE \
  SPNG_AFTER_IHDR SPNG_AFTER_PLTE SPNG_AFTER_IDAT SPNG_KEEP_UNKNOWN_CHUNKS \
  SPNG_IMG_COMPRESSION_LEVEL SPNG_IMG_WINDOW_BITS SPNG_IMG_MEM_LEVEL \
  SPNG_IMG_COMPRESSION_STRATEGY SPNG_TEXT_COMPRESSION_LEVEL SPNG_TEXT_WINDOW_BITS \
  SPNG_TEXT_MEM_LEVEL SPNG_TEXT_COMPRESSION_STRATEGY SPNG_FILTER_CHOICE \
  SPNG_CHUNK_COUNT_LIMIT SPNG_ENCODE_TO_BUFFER
do
  set -- "$@" --include-constant "$symbol"
done

"$@" "$ROOT/jextract/libspng_api.h"

perl -0777 -pi -e \
  's/static final SymbolLookup SYMBOL_LOOKUP = .*?;/static final SymbolLookup SYMBOL_LOOKUP = io.github.ghosthack.libspngffm.LibSpngLibs.lookup();/s' \
  "$GEN_DIR/LibSpng.java"
find "$GEN_DIR" -type f -name '*.java' -exec perl -0777 -pi -e 's/\s+\z/\n/' {} +

if grep -rn "$PREFIX" "$GEN_DIR" >/dev/null; then
  echo "ERROR: build-prefix paths survived in generated stubs"; exit 1
fi
grep -q "LibSpngLibs.lookup()" "$GEN_DIR/LibSpng.java" \
  || { echo "ERROR: lookup patch did not apply"; exit 1; }

echo "Generated $(find "$GEN_DIR" -type f | wc -l | tr -d ' ') files into $GEN_DIR"
