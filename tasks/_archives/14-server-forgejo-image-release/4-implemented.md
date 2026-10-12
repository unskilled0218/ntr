# implemented

## changes

- Created fresh `14-server-forgejo-image-release` branches in the parent and server repositories.
- Added a target-platform multi-stage `server/Dockerfile`: a Rust Bookworm build stage compiles the locked release binary; a Debian Bookworm slim runtime contains the binary, curl, certificates, and runtime libraries. It runs as UID/GID `1000:1000` with `/data` defaults and an exec-form entry point. Both amd64 and arm64 use their matching base-image/binary architecture.
- Added a whitelist-style `.dockerignore`, admitting only Dockerfile/build manifests/lockfile and Rust source. Runtime data, credentials, caches, Git files, scripts, tests, and documentation stay outside the image build context.
- Added executable `server/scripts/release.sh` with Bash strict mode and Python preflight. Its standard-library `scripts/image_release.py` helper handles JSON, configuration, subprocesses, builder isolation, and digest-bound registry decisions; this decomposition avoids duplicating large JSON parsers in Bash.
- The publisher derives the server version from locked Cargo metadata, requires a clean server `main`, resolves the token login through Forgejo or accepts `FORGEJO_USERNAME`, and defaults to the `git.lan/ntr/ntr-server` package repository. It builds and pushes both `linux/amd64` and `linux/arm64` under one version tag with OCI version/revision/source labels.
- Docker credentials use a private temporary configuration. The helper preserves original Buildx state, engine/TLS environment paths, required named contexts for all builder nodes, plugin directories, and build proxy settings. It pins the existing `docker-container` builder and checks its driver, node identities/status, and both platforms after isolation. It normalizes relative connection paths against the caller's working directory. It does not change the user's global context/builder selection or copy unrelated registry logins.
- Builder metadata comes from an explicit JSON wrapper around `buildx ls`'s Builder/Current fields; `buildx inspect --bootstrap` only boots/verifies the pinned builder. Docker's `inspect` command has no `--format` option, and older Buildx builder JSON omits the promoted Current field, so the wrapper handles that CLI boundary explicitly.
- One registry inspection path parses manifest/config JSON, pins child reads to immutable digests, accepts ARM64/v8, filters explicitly marked attestations, and requires both platform configurations to match the expected version/revision. A new push must match Buildx's `containerimage.digest` metadata and the final tag resolution. Complete matching releases are reused; malformed, incomplete, conflicting, moved-tag, or ambiguous states fail without authorizing an overwrite.
- Tokens travel through login stdin or curl configuration stdin, not command arguments/build arguments. Child command environments omit `FORGEJO_TOKEN`; captured diagnostics redact it. Temporary credentials and context archives are removed on success, failure, Ctrl-C, and handled termination. Missing-manifest handling accepts only the exact exit-1 diagnostics documented in the release guide, not generic `not found` substrings.
- Updated `server/docker-compose.yml` to pull `git.lan/ntr/ntr-server:0.2.2` with automatic host architecture selection. Removed source compilation/mounts and Cargo cache volumes; retained `./data:/data`, existing runtime paths, and restart policy. Added image/UID/GID overrides, configurable loopback-default host binding/port, creation-date configuration, and a corrected curl health check with a 30-second binary-startup grace period.
- Added dedicated `server/docs/image-release.md`, rewrote `docs/docker-compose.md` for image deployment, permissions, authentication, upgrades/rollback, and digest selection, and added one README link.
- Added real-entry-point release tests using Bash, disposable real Git checkouts, and controlled Docker/Cargo/curl command seams. Coverage includes working directories with spaces, configuration/username overrides, relative connection paths, credential isolation/cleanup, both platforms, failure/rerun states, metadata/index/config validation, and handled termination. Added Python bytecode ignores.

## version and decisions

- Updated server Cargo.toml and its package entry in Cargo.lock from `0.2.1` to `0.2.2`, with no dependency changes. Compose and current release examples use `0.2.2`; the script reads future versions dynamically.
- The explicit implementation instruction requires a project version update. This patch bump supersedes the plan's proposed unchanged initial image version; no other plan scope changed.
- The publisher does not create Git tags, Forgejo release attachments, a mutable latest tag, or source pushes. Package publishing needs `write:package` and owner access; token-only username lookup additionally needs `read:user`, while an explicit username bypasses the API lookup.
- Runtime data must be writable by the documented numeric user. Compose exposes `NTR_UID`/`NTR_GID`; it does not automatically change host ownership. The native smoke fixture uses disposable data rather than existing `server/data` files.

## verification

- `bash -n scripts/release.sh` in server: passed.
- Final `python3 -m unittest discover -s tests -p 'release_script_test.py' -v` in server: passed, 13 test groups with scenario matrices. Tests inspect actual subprocess arguments/stdin/output, both platform config requests, original configuration preservation, cleanup after failures and termination, and absence of secret-bearing child environments/command arguments.
- `cargo test --locked` in server: passed, 23 unit tests, 11 API tests, and three task-date/persistence integration tests, plus empty binary/doc targets: 37 tests total.
- `cargo build --release --locked --bin my-ntr-server` in server: passed for the native Linux amd64 environment.
- `python3 /tmp/opencode/ntr-native-image-smoke.py target/release/my-ntr-server`: passed against the actual release binary. It checked HTTP health, task edits, note/label writes, restart persistence for all three resources, and external task/note edits using a disposable directory. Two startup measurements were approximately 0.008 and 0.051 seconds. This is native-process evidence, not container or ARM64 evidence.
- `ldd target/release/my-ntr-server`: native release dependencies resolved (`libgcc_s`, `libm`, libc, and the ELF loader); no missing native libraries were reported. Container linkage still needs an actual image build/run.
- Docker Hub's tag metadata for `rust:1-bookworm` and `debian:bookworm-slim` was checked through their public tag endpoints; both currently list Linux amd64 and arm64/v8 images.
- Relative README/documentation targets were checked against the dedicated docs files. `git diff --check` passed; staged checks also cover newly added files. The release entry point has executable Git mode.

## runtime limits and remaining verification

- Docker, Buildx, Compose, and ShellCheck are not installed on PATH. No image was built, started, pulled, or pushed, and no Forgejo package or Git release/tag was published. Fixture digests are test data, not actual release outputs.
- Actual `docker compose config`, image UID/GID bind-mount behavior, amd64/arm64 container startup/persistence, Buildx isolation against a real engine, and live registry missing-manifest diagnostics remain unverified. The 30-second grace period is based on native binary startup rather than measured container startup.
- The Docker/Buildx CLI contracts were checked against official command documentation and Buildx formatter source, including its 0.13 interface. No real client/engine version is claimed as tested. The release guide records this limitation and explains fail-closed handling of unrecognized diagnostics.
- Completing runtime verification requires a user-provided Docker CLI with Buildx and Compose, a reachable `docker-container` builder supporting both architectures, native or configured emulated runtime capability for both, and Forgejo package access. No system prerequisites, daemon trust, host emulation, or host data ownership were changed.
- Live publication follows a committed server `main` checkout. This implementation remains on its task branch, consistent with the requested workflow; the publisher intentionally rejects feature branches and dirty server trees.

## commits

- Server commit: `d4d91e4` — `Build and publish multi-platform server images to Forgejo`.
- The parent implementation commit records this server revision and the implementation report. Existing unrelated parent changes are excluded.

## Fixed builder follow-up

- The publisher now always uses the existing `ntr-release` builder, regardless of the caller's `BUILDX_BUILDER` or current builder selection. Docker subprocesses receive the fixed builder before preflight, and missing-builder errors include its creation command.
- Updated the release guide and existing command fixtures. The override scenario supplies `BUILDX_BUILDER=other-builder`, marks `ntr-release` as not current, and verifies Docker still uses `ntr-release` throughout.
- `bash -n scripts/release.sh`, all 13 release test groups, and `git diff --check` passed. No live registry publication was attempted.
- Server commit: `7d939ae` — `Always use ntr-release builder for image publishing`. The parent follow-up commit records the server revision and this existing report.

## Git username follow-up

- The registry login now defaults to the server checkout's effective `git config user.name`, with `FORGEJO_USERNAME` retained as an explicit override. Removed API username lookup, the API URL setting, and the publisher's curl prerequisite.
- Updated existing documentation and fixtures. Tests verify the Git username, explicit override, rejection of empty/display names, and successful override when Git names are invalid. The fixture no longer provides curl.
- `bash -n scripts/release.sh`, all 14 release test groups, and server `git diff --check` passed. No live registry publication was attempted.
- Server commit: `c0c06f8` — `Use Git configuration for Forgejo release username`. The parent follow-up commit records this server revision and report.

## Release logging follow-up

- Added timestamped stderr progress for checkout/version checks, builder/context setup, registry login and inspection, tests, build/push, per-platform verification, and temporary credential removal. Final references and digests stay on stdout.
- Builder bootstrap, Cargo tests, and Buildx build/push now stream merged stdout/stderr as complete lines arrive. Buildx uses `--progress plain`. Output and command announcements redact the supplied token, including a token split across child writes; login stdin is not logged. Interrupted streaming commands kill and wait for their child before temporary-directory cleanup.
- Updated the release guide with output behavior and a Bash `pipefail`/`tee` example. The existing fixture verifies output arrives while the build is still blocked, token redaction, both child streams, release stages, and plain-progress arguments.
- `bash -n scripts/release.sh`, all 15 release test groups, and server `git diff --check` passed. No live publication was attempted.
- Server commit: `4c53e9d` — `Stream release progress and redact command output`. The parent follow-up commit records this server revision and report.

## Automatic builder and release archive follow-up

- Automatically creates missing `ntr-release` with the `docker-container` driver, using existing `~/.config/buildkit/buildkitd.toml` when present. `BUILDKIT_CONFIG` selects another existing file. Existing builders are reused, and creation does not select a new global current builder or install emulation.
- Exports the already verified registry index through `skopeo copy --all --preserve-digests`, avoiding a second build with potentially different contents. Compresses the multi-platform OCI archive and validates blob hashes, the original index, both platform manifests, and their referenced configs/layers before upload.
- Writes ignored local `server/release/<version>/img.tar.gz` and `img.tar.gz.sha256` and uploads both to the server repository's Forgejo Release `v<version>`. Forgejo may create the remote Git tag at the intended revision. This supersedes the original registry-only/no-release-tag policy; the script still does not push source.
- Checks that the committed source revision exists in Forgejo before builder/push operations. Rejects conflicting release descriptions or remote tag revisions. Complete reruns verify downloaded archive/checksum attachments without rebuilding or reuploading; an archive-only partial upload resumes the missing checksum. Failed uploads preserve existing assets for inspection and retry.
- Restored curl as an API/upload prerequisite and added Skopeo. `FORGEJO_API_URL` identifies the complete repository API endpoint. `FORGEJO_CA_FILE` supplies custom CA trust to curl and Skopeo, independently of BuildKit's configured CA. Tokens now require package-write and repository-write access. TLS verification remains enabled.
- Added an empty, non-secret authentication placeholder to temporary Docker configuration to suppress automatic native credential-helper selection. This keeps Docker login file-backed for Skopeo and addresses the persistent-credential-store issue recorded in the original code review. Original Docker credentials remain uncopied.
- Updated existing release docs and fixtures. New scenarios cover builder creation/config reuse/errors, CA arguments, real fixture tar/gzip/checksum integrity, missing/corrupted blobs, source/tag/release identity, attachment failures and reruns, checksum tampering, API errors, untrusted attachment hosts, and absent Skopeo.
- `bash -n scripts/release.sh`, all 24 release test groups, and server/parent `git diff --check` passed. The final test run took approximately 43 seconds. The exact builder-list template also succeeded against the real Docker CLI with `BUILDX_BUILDER=ntr-release`.
- Skopeo is not installed in this workspace. Its `--all`, `--preserve-digests`, `--src-authfile`, `--src-cert-dir`, and OCI-archive contracts were checked against upstream documentation. Actual Skopeo export, automatic creation against a real engine, custom-CA client connections, and Forgejo release creation/uploads remain unverified. No system prerequisites were installed and no live release was published.
- Server commit: `0888c9f` — `Create release builder and publish image archive attachments`. The parent follow-up commit records this server revision and report.

## Registry export without Skopeo follow-up

- Removed Skopeo preflight/export calls. Forgejo image/release publication, `ntr-release` setup, username configuration, archive/checksum names, and rerun behavior remain available through the same entry point.
- A dedicated registry downloader uses existing curl and Python's standard library to fetch the verified index, all platform/attestation manifests, configurations, and layers by immutable digest. Shared blobs are downloaded once, every download is SHA-256 checked, and the original manifest bytes are preserved in the generated OCI archive.
- Supports Basic authentication and registry Bearer-token challenges with repository pull scope. Authentication values travel through curl configuration stdin, stay out of child environments/arguments, and are redacted from captured diagnostics. HTTPS external blob redirects receive no registry credentials; insecure redirects and token endpoints outside the registry's HTTPS origin are rejected. Explicit HTTPS port 443 is treated as the default origin.
- Installed CA trust remains the default. `FORGEJO_CA_FILE` optionally supplies registry/API trust; external storage uses curl's default trust settings. Registry downloads disable `.curlrc` to avoid implicit credential or insecure-option injection. The archive contains only OCI layout data, not authentication or certificate files.
- Updated existing docs and fixtures to run without a Skopeo executable. Added protocol scenarios for Basic/Bearer auth, explicit default ports, denied tokens/blobs, external redirects, untrusted token endpoints, redirect loops, and secret-bearing curl failures. Existing artifact integrity and partial-upload/reuse scenarios remain covered.
- `bash -n scripts/release.sh`, all 28 release test groups, and server/parent `git diff --check` passed. The final suite took approximately 69 seconds and runs with no Skopeo executable on its fixture PATH. Live authenticated registry downloads and real Forgejo uploads were not attempted. No new package was installed.
- Server commit: `a692717` — `Export release archives without Skopeo`. The parent follow-up commit records this server revision and report.
