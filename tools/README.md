# Tools

`jextract/gen-bindings.sh` defaults to the JDK 22 jextract distribution in
`../ffmpeg-ffm/tools/jextract-22`. Set `JEXTRACT=/path/to/jextract` to use a
different installation. Stub regeneration is only needed when the public API
or upstream headers change; ordinary Maven builds compile the checked-in Java
sources.
