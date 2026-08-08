package io.github.ghosthack.libspngffm;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.lang.foreign.Arena;
import java.lang.foreign.Linker;
import java.lang.foreign.SymbolLookup;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

/** Resolves the zlib and libspng shared libraries used by the generated stubs. */
public final class LibSpngLibs {
    private static final Arena LIBRARY_ARENA = Arena.ofAuto();
    private static volatile SymbolLookup lookup;

    private LibSpngLibs() {}

    /**
     * Returns a lazily initialized lookup over zlib, libspng, and host fallbacks.
     * Resolution order is an explicit library directory, bundled natives, then
     * libraries already loaded by the application or operating system.
     */
    public static SymbolLookup lookup() {
        SymbolLookup current = lookup;
        if (current == null) {
            synchronized (LibSpngLibs.class) {
                current = lookup;
                if (current == null) {
                    lookup = current = resolve();
                }
            }
        }
        return current;
    }

    private static SymbolLookup resolve() {
        String override = System.getProperty("libspngffm.libdir", System.getenv("LIBSPNG_FFM_LIBDIR"));
        SymbolLookup resolved = override != null ? fromDirectory(Path.of(override)) : fromBundle();
        SymbolLookup fallback = SymbolLookup.loaderLookup().or(Linker.nativeLinker().defaultLookup());
        return resolved != null ? resolved.or(fallback) : fallback;
    }

    private static SymbolLookup fromDirectory(Path directory) {
        if (!Files.isDirectory(directory)) {
            throw new IllegalStateException("libspngffm.libdir does not exist: " + directory);
        }
        List<Path> libraries = new ArrayList<>();
        try (var files = Files.list(directory)) {
            files.filter(LibSpngLibs::isLibrary).sorted().forEach(libraries::add);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        if (libraries.stream().noneMatch(LibSpngLibs::isSpngLibrary)) {
            throw new IllegalStateException("no libspng shared library found in " + directory);
        }
        libraries.sort((left, right) -> Integer.compare(loadRank(left), loadRank(right)));
        return chain(libraries);
    }

    private static boolean isLibrary(Path path) {
        String name = path.getFileName().toString().toLowerCase();
        boolean extension = name.endsWith(".dylib") || name.endsWith(".dll") || name.contains(".so");
        return extension && (isZlibLibrary(path) || isSpngLibrary(path));
    }

    private static boolean isZlibLibrary(Path path) {
        String name = path.getFileName().toString().toLowerCase();
        return name.startsWith("libz.") || name.equals("libz.dylib") || name.equals("libz.dll")
                || name.equals("z.dll") || name.equals("zlib1.dll");
    }

    private static boolean isSpngLibrary(Path path) {
        return path.getFileName().toString().toLowerCase().contains("spng");
    }

    private static int loadRank(Path path) {
        return isZlibLibrary(path) ? 0 : 1;
    }

    private static SymbolLookup fromBundle() {
        String classifier = classifier();
        String base = "libspng-natives/" + classifier + "/";
        List<String> manifest = readManifest(base);
        if (manifest == null) {
            return null;
        }
        Path cacheDirectory = Path.of(System.getProperty("user.home"), ".cache", "libspng-ffm",
                Version.VERSION + "-" + classifier);
        try {
            Files.createDirectories(cacheDirectory);
            List<Path> libraries = new ArrayList<>();
            for (String name : manifest) {
                libraries.add(extract(base + name, cacheDirectory.resolve(name)));
            }
            return chain(libraries);
        } catch (IOException e) {
            throw new UncheckedIOException("failed to extract bundled libspng natives to "
                    + cacheDirectory, e);
        }
    }

    private static List<String> readManifest(String base) {
        try (InputStream in = LibSpngLibs.class.getClassLoader()
                .getResourceAsStream(base + "manifest.txt")) {
            if (in == null) {
                return null;
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).lines()
                    .map(String::trim).filter(line -> !line.isEmpty()).toList();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static Path extract(String resource, Path target) throws IOException {
        try (InputStream in = LibSpngLibs.class.getClassLoader().getResourceAsStream(resource)) {
            if (in == null) {
                throw new IOException("missing classpath resource " + resource);
            }
            byte[] bytes = in.readAllBytes();
            if (Files.exists(target) && Files.size(target) == bytes.length) {
                return target;
            }
            Path temporary = Files.createTempFile(target.getParent(), target.getFileName().toString(), ".tmp");
            Files.write(temporary, bytes);
            try {
                Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING,
                        StandardCopyOption.ATOMIC_MOVE);
            } catch (java.nio.file.AtomicMoveNotSupportedException ignored) {
                Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING);
            }
            return target;
        }
    }

    private static SymbolLookup chain(List<Path> libraries) {
        SymbolLookup result = null;
        for (Path library : libraries) {
            SymbolLookup one = SymbolLookup.libraryLookup(
                    library.toAbsolutePath().toString(), LIBRARY_ARENA);
            result = result == null ? one : result.or(one);
        }
        return result;
    }

    static String classifier() {
        String os = System.getProperty("os.name", "").toLowerCase();
        String arch = System.getProperty("os.arch", "").toLowerCase();
        String osPart = os.contains("mac") ? "macos" : os.contains("win") ? "windows" : "linux";
        String archPart = arch.equals("aarch64") || arch.equals("arm64") ? "arm64" : "x64";
        return osPart + "-" + archPart;
    }
}
