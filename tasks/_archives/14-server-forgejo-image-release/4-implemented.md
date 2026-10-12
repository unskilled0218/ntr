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
