# Publishing

Releases use the same Maven Central workflow as `ffmpeg-ffm`.

1. Set a non-SNAPSHOT version in the parent and both child POM parent entries.
2. Push a matching tag such as `v0.7.4-0.1.0` and publish a non-prerelease
   GitHub Release for it.
3. The release workflow builds and tests native jars on macOS arm64, Windows
   x64, and Linux x64, then deploys one signed Central bundle.

The repository needs `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`,
`GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE` secrets. The Central account and GPG
key setup are identical to the sibling project.

Builds use the Maven Wrapper (`./mvnw`), which pins Maven 3.9.16. Do not
switch the release to the runner's `mvn`: under Maven 3.10 the
central-publishing plugin (0.11.0) stages resolver files such as
`_remote.repositories` and `maven-metadata-local.xml` into the bundle, and
Central rejects it with "Bundle has content that does NOT have a .pom file".

To inspect the signed bundle CI would upload, run the Release workflow
manually (optionally with a throwaway `version`). It builds the natives on all
three platforms, then builds the bundle against an unreachable Central URL with
placeholder credentials and attaches `central-bundle.zip` as a workflow
artifact; nothing is published.
