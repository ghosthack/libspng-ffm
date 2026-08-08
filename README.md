# libspng-ffm

Panama FFM (jextract) bindings for the complete libspng 0.7.4 API with bundled,
from-source libspng 0.7.4 and zlib 1.3.2 natives. One Maven coordinate,
batteries included: no user-installed libspng or zlib, and no JNI.

| Artifact | Contents | License |
|---|---|---|
| `io.github.ghosthack:libspng-ffm` | Generated JDK 22 FFM stubs and runtime loader | MIT |
| `io.github.ghosthack:libspng-ffm-natives` | libspng and zlib shared libraries | BSD-2-Clause / libpng-2.0 / zlib License |

The binding exposes the whole public header: in-memory, stream, and file I/O;
decode and encode; progressive rows and scanlines; metadata chunks; limits and
compression options; custom allocators; and read/write callbacks.

## Use

```xml
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libspng-ffm</artifactId>
  <version>0.7.4-0.1.0-SNAPSHOT</version>
</dependency>
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>libspng-ffm-natives</artifactId>
  <version>0.7.4-0.1.0-SNAPSHOT</version>
  <classifier>macos-arm64</classifier> <!-- windows-x64 or linux-x64 -->
  <scope>runtime</scope>
</dependency>
```

When using the module path, declare `requires libspng.ffm;` and run with
`--enable-native-access=libspng.ffm`. On the class path, use
`--enable-native-access=ALL-UNNAMED`. JDK 22 or newer is required.

```java
import io.github.ghosthack.libspngffm.spng.LibSpng;
import io.github.ghosthack.libspngffm.spng.spng_ihdr;

try (Arena arena = Arena.ofConfined()) {
    MemorySegment png = arena.allocateFrom(ValueLayout.JAVA_BYTE, pngBytes);
    MemorySegment context = LibSpng.spng_ctx_new(0);
    if (context.equals(MemorySegment.NULL)) throw new OutOfMemoryError();
    try {
        check(LibSpng.spng_set_png_buffer(context, png, pngBytes.length));

        MemorySegment header = spng_ihdr.allocate(arena);
        check(LibSpng.spng_get_ihdr(context, header));

        MemorySegment outputSize = arena.allocate(ValueLayout.JAVA_LONG);
        check(LibSpng.spng_decoded_image_size(
                context, LibSpng.SPNG_FMT_RGBA8(), outputSize));
        MemorySegment rgba = arena.allocate(outputSize.get(ValueLayout.JAVA_LONG, 0));
        check(LibSpng.spng_decode_image(
                context, rgba, rgba.byteSize(), LibSpng.SPNG_FMT_RGBA8(), 0));
    } finally {
        LibSpng.spng_ctx_free(context);
    }
}
```

Here `check()` should treat `SPNG_OK` as success and use
`LibSpng.spng_strerror(result).getString(0)` for failures. See
`LibSpngSmokeTest` for a complete in-memory RGBA encode/decode round trip,
including a Java write callback.

## Native resolution

`LibSpngLibs.lookup()` resolves in this order:

1. `-Dlibspngffm.libdir=<dir>` or `LIBSPNG_FFM_LIBDIR` (the directory must
   contain libspng and may contain zlib);
2. the platform classifier jar, extracted once under
   `~/.cache/libspng-ffm/<version>-<platform>/`, with zlib loaded first;
3. libraries already loaded by the application and the system lookup.

Supported classifiers are `macos-arm64`, `windows-x64`, and `linux-x64`.

## Build

Fetch the exact upstream sources:

```sh
mkdir -p build
curl -sfL https://github.com/randy408/libspng/archive/refs/tags/v0.7.4.tar.gz | tar xz -C build
curl -sfL https://github.com/madler/zlib/archive/refs/tags/v1.3.2.tar.gz | tar xz -C build
```

Then, on the target platform:

```sh
build-natives/macos-arm64.sh  # or linux-x64.sh / windows-x64.sh from MINGW64
jextract/gen-bindings.sh      # regeneration is done on macOS
mvn clean install
```

The native scripts build both projects as shared libraries and stage zlib and
libspng together. Generated Java layouts are portable across the supported
64-bit ABIs.
