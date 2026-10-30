# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Limitations and required setup](#limitations-and-required-setup)
- [Commits](#commits)

## Changes

- Created new `32-align-app-release-process` branches in the parent repository and app submodule; did not reuse existing branches.
- Replaced the app's previous publisher with a Bash entry point and Python helpers for strict local metadata validation, private token-file authentication, clean already-pushed `main`, destination checks, local locking, and guarded Forgejo artifact publication.
- Added versioned canonical annotated-tag identities and manifests covering source, configuration/scripts/notes, target selection, required artifact names, sizes, SHA-256 digests, and checksum contents. Publication pushes only the version tag, never source or unrelated tags.
- Added an early remote-state decision: absent releases build from an isolated checkout; complete releases download and verify original manifest-bound bytes without builds, tests, dependency installation, or signing-key access; partial or conflicting states stop without automatic repair or destructive cleanup.
- New builds use fresh outputs, locked npm dependencies, frontend and native tests, and tracked-source checks before and after builds. Linux desktop publication requires AppImage, deb, and rpm. Android builds a universal APK only, checks its signature and expected public certificate, and never builds/uploads an AAB.
- Added gitignored `app/android-signing/` storage, restrictive permissions, explicit first-key creation and legacy-key migration, public fingerprint display, Gradle integration, temporary build-input copies, preservation of original keys, and backup guidance. No actual signing keys were created, moved, opened, staged, or pushed.
- Added bounded HTTPS requests, same-origin-only GET redirects, streaming multipart uploads without automatic retries, full remote asset inventory checks, and secret-safe tool errors. Download verification uses attachment browser URLs rather than the JSON metadata endpoint.
- Updated app and parent READMEs and dedicated release/build/signing documentation. Bumped all app version mirrors to `0.15.28` and added its release notes. Server implementation and `todo.md` were not changed.

## Verification

- Passed: `python3 -B -m unittest discover -s tests -p 'test_release*.py' -v` — 36 tests, with additional parameterized subcases. Tests use real temporary local Git repositories and fake build/API adapters; transport tests inspect bounded downloads, redirects, API identity, and multipart bytes without live network publication.
- Covered successful artifact publication, exact-tag-only push even with `push.followTags=true`, completed-release verification with builds/signing access prohibited, incomplete and conflicting inventories, altered metadata/assets/checksums, stale or missing artifacts, wrong signatures/certificates, local lock contention, tracked-source changes, concurrent remote appearance, token permissions, migration preservation, and uncertain Git/release/asset writes. A lost final upload response can subsequently verify complete read-only, without repeat writes.
- Passed: `npm test` — 722 tests across 45 files.
- Passed: `npm run build` — TypeScript and Vite production frontend build.
- Passed: `npm run test:task-contract` — local and current-server serializer/save/reload/lifecycle checks. The optional old-server checks were explicitly skipped because `OLD_NTR_SERVER_BIN` was unset. This cross-repository command was run for implementation verification; isolated release builds instead run app-only frontend and native tests and do not depend on a sibling server checkout.
- Passed: `cargo test --locked --lib` — 62 passed, one existing integration test ignored because it requires `MY_NTR_SERVER_BIN`.
- Passed: `cargo clippy --all-targets --locked`.
- Passed: Bash syntax checks for `release.sh`, `build-release.sh`, and `android-keystore.sh`; direct executable `release.sh --help` and `--validate`; app and parent `git diff --check`.
- Not passed: `cargo fmt --check` reports existing formatting differences in untouched `src-tauri/build.rs`, `src-tauri/src/http.rs`, `src-tauri/src/http_tests.rs`, and `src-tauri/src/main.rs`. No Rust `.rs` files were changed; unrelated formatting was left intact.

## Limitations and required setup

- `keytool`, `apksigner`, and an existing signing key were unavailable in this checkout. Real Android builds, actual key migration/creation, and device install/update behavior were not verified. Prepared JDK/SDK/NDK tools and signing files are still required; the publisher never installs system tools.
- `android_certificate_sha256` is deliberately `null` in `app/scripts/release.json` because no trusted existing certificate could be established here. Local `--validate` passes structural/version checks and explicitly reports this setup requirement; new Android publication refuses until the owner establishes and commits the trusted public fingerprint. No placeholder identity is silently accepted for signing.
- Real desktop bundling and deployed Forgejo API/authentication/attachment behavior were not exercised. Local fake services do not certify live permissions, upload limits, server versions, or external object-storage compatibility. Only same-origin HTTPS attachment downloads/GET redirects are supported. Obtain separate approval before live compatibility checks or publication.
- No release/tag/source was pushed to a real remote. All publication writes during tests targeted temporary local Git repositories and simulated API state. Version `0.15.28` is prepared, not published.

## Commits

- App implementation: `2f4f7e9` (`Align app releases with guarded server publication`).
- The parent implementation commit records this report, the relevant README update, and the app submodule pointer.
