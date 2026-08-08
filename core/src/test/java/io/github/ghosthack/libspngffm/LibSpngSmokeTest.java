package io.github.ghosthack.libspngffm;

import io.github.ghosthack.libspngffm.spng.LibSpng;
import io.github.ghosthack.libspngffm.spng.spng_ihdr;
import io.github.ghosthack.libspngffm.spng.spng_rw_fn;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** End-to-end encode/decode proof using the bundled libspng and zlib natives. */
class LibSpngSmokeTest {

    @Test
    void reportsExpectedVersion() {
        assertEquals("0.7.4", LibSpng.spng_version_string().getString(0));
        assertNotEquals(MemorySegment.NULL, LibSpng.spng_strerror(LibSpng.SPNG_EINVAL()));
    }

    @Test
    void encodesAndDecodesRgbaInMemory() {
        int width = 7;
        int height = 5;
        byte[] pixels = new byte[width * height * 4];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int offset = (y * width + x) * 4;
                pixels[offset] = (byte) (x * 31);
                pixels[offset + 1] = (byte) (y * 47);
                pixels[offset + 2] = (byte) (x * 11 + y * 13);
                pixels[offset + 3] = (byte) 0xff;
            }
        }

        try (Arena arena = Arena.ofConfined()) {
            MemorySegment encoder = LibSpng.spng_ctx_new(LibSpng.SPNG_CTX_ENCODER());
            assertNotEquals(MemorySegment.NULL, encoder);
            byte[] encodedBytes;
            try {
                ByteArrayOutputStream output = new ByteArrayOutputStream();
                MemorySegment writer = spng_rw_fn.allocate((ctx, user, source, length) -> {
                    output.writeBytes(source.reinterpret(length).toArray(ValueLayout.JAVA_BYTE));
                    return LibSpng.SPNG_OK();
                }, arena);
                check(LibSpng.spng_set_png_stream(encoder, writer, MemorySegment.NULL));
                MemorySegment ihdr = spng_ihdr.allocate(arena);
                spng_ihdr.width(ihdr, width);
                spng_ihdr.height(ihdr, height);
                spng_ihdr.bit_depth(ihdr, (byte) 8);
                spng_ihdr.color_type(ihdr, (byte) LibSpng.SPNG_COLOR_TYPE_TRUECOLOR_ALPHA());
                check(LibSpng.spng_set_ihdr(encoder, ihdr));

                MemorySegment source = arena.allocateFrom(ValueLayout.JAVA_BYTE, pixels);
                check(LibSpng.spng_encode_image(encoder, source, pixels.length,
                        LibSpng.SPNG_FMT_PNG(), LibSpng.SPNG_ENCODE_FINALIZE()));
                encodedBytes = output.toByteArray();
                assertTrue(encodedBytes.length > 8);
            } finally {
                LibSpng.spng_ctx_free(encoder);
            }

            MemorySegment encoded = arena.allocateFrom(ValueLayout.JAVA_BYTE, encodedBytes);
            MemorySegment decoder = LibSpng.spng_ctx_new(0);
            assertNotEquals(MemorySegment.NULL, decoder);
            try {
                check(LibSpng.spng_set_png_buffer(decoder, encoded, encodedBytes.length));
                MemorySegment decodedHeader = spng_ihdr.allocate(arena);
                check(LibSpng.spng_get_ihdr(decoder, decodedHeader));
                assertEquals(width, spng_ihdr.width(decodedHeader));
                assertEquals(height, spng_ihdr.height(decodedHeader));

                MemorySegment decodedSize = arena.allocate(ValueLayout.JAVA_LONG);
                check(LibSpng.spng_decoded_image_size(decoder, LibSpng.SPNG_FMT_RGBA8(), decodedSize));
                assertEquals(pixels.length, decodedSize.get(ValueLayout.JAVA_LONG, 0));
                MemorySegment decoded = arena.allocate(pixels.length);
                check(LibSpng.spng_decode_image(decoder, decoded, pixels.length,
                        LibSpng.SPNG_FMT_RGBA8(), 0));
                assertArrayEquals(pixels, decoded.toArray(ValueLayout.JAVA_BYTE));
            } finally {
                LibSpng.spng_ctx_free(decoder);
            }
        }
    }

    private static void check(int result) {
        assertEquals(LibSpng.SPNG_OK(), result,
                () -> LibSpng.spng_strerror(result).getString(0));
    }
}
