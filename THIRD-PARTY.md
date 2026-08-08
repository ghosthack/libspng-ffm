# Third-party software

The Java binding and loader are MIT licensed. Classifier jars additionally
contain unmodified binaries built from these upstream projects:

| Component | Version | Source | License |
|---|---:|---|---|
| libspng | 0.7.4 | https://github.com/randy408/libspng | BSD-2-Clause and PNG Reference Library License v2 |
| zlib | 1.3.2 | https://github.com/madler/zlib | zlib License |

libspng's SIMD optimizations contain code derived from libpng under the PNG
Reference Library License version 2. Each native jar includes
`LICENSE-libspng.txt`, `LICENSE-libpng-2.0.txt`, `LICENSE-zlib.txt`, and a
`BUILD-INFO.txt` file beside the native libraries. Neither dependency is
modified. The platform scripts build shared libraries from the corresponding
release source archives.
