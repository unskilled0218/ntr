# plan

- [Scope](#scope)
- [Implementation plan](#implementation-plan)
  - [1. Define the app release contract](#1-define-the-app-release-contract)
  - [2. Implement guarded publication](#2-implement-guarded-publication)
  - [3. Test the release workflow](#3-test-the-release-workflow)
  - [4. Update documentation](#4-update-documentation)
- [Acceptance criteria](#acceptance-criteria)
- [Risks and decisions](#risks-and-decisions)

## Scope

Align the app's release process with the server's guarded publication workflow while publishing app artifacts rather than container images. Work in the `app` submodule; do not change the server release process or publish a release during implementation.

Android releases cover directly distributed signed APKs only. AAB generation, AAB publication, and Google Play App Signing are out of scope. Keep local signing secrets in the app's gitignored `android-signing/` directory; never commit or push them.

## Implementation plan

### 1. Define the app release contract

- Inspect `server/scripts/release.sh`, its helpers, tests, and release documentation for the applicable source, authentication, validation, locking, and retry rules. Adapt them for artifacts rather than copying image or package-association operations.
- Add app release configuration equivalent to `server/scripts/release.json`, identifying the Forgejo repository, username, private token file, release notes, and supported artifact targets. Use `package.json`'s `version` as the canonical version; validate both `package-lock.json` root version fields (`version` and `packages[""].version`), `src-tauri/tauri.conf.json`, `src-tauri/Cargo.toml`, and the app entry in `src-tauri/Cargo.lock` against it.
- Add versioned release notes with the server's `# Release v<version>` convention. Bind the release identity to the exact source commit, relevant configuration, scripts, notes, selected targets, and an artifact manifest containing names and SHA-256 digests. Define a versioned UTF-8 JSON tag payload with explicit schema, version, source commit, hashes of configuration, scripts and notes, sorted unique targets, and a name-sorted manifest of asset names, sizes, and SHA-256 hashes. Serialize with sorted object keys and no insignificant whitespace; reject duplicate keys, unknown schema versions, malformed fields, and noncanonical payloads. Compare identity fields and manifest entries exactly.
- For the existing Linux desktop build, require one AppImage, one deb, and one rpm; for Android, require one signed universal APK only. No other artifact formats are part of this contract. Require exactly one of each selected format, generate a `.sha256` file for each, and reject duplicate asset or checksum basenames across targets. Fail before publication if any required format is missing or cannot be built; verify APK signatures with the Android signing tools. Configure the Android build and collector for APK only; do not build, require, collect, or upload AAB files. Keep the existing build entry point usable, but never assume files already in `release/<version>/` came from the current source.

### 2. Implement guarded publication

- Replace `app/scripts/release.sh` with a server-style entry point supporting `--help`, credential-free and network-free `--validate`, and an explicitly documented publication mode. Preserve desktop and Android selection with a clear, immutable target set per release.
- Require a clean, already-pushed `main`, matching configured fetch and push destinations, normal TLS verification, validated private token-file ownership and permissions, necessary tools, and exclusive local execution. Do not push source or unrelated tags; do not accept legacy token-value or endpoint overrides silently.
- Add `/android-signing/` to `app/.gitignore` before creating or moving signing secrets. Store `release.keystore` and `keystore.properties` in `app/android-signing/`, with directory mode `0700` and file modes `0600`. Update `scripts/android-keystore.sh` and the Gradle signing integration to use this location. Preserve the existing signing key; if legacy files exist under `src-tauri/gen/android/`, provide an explicit migration that refuses overwrites and verifies the existing certificate fingerprint. Never generate a replacement key automatically, stage signing files, or push them.
- Run applicable app tests and build the selected targets from the verified commit in a temporary isolated checkout with fresh build and output directories, not the original checkout's ignored artifacts. Prepare dependencies from committed lockfiles and build the tracked Android project without regenerating or overwriting its Gradle configuration or other tracked files. Generate only explicitly identified missing ignored support files required by the documented toolchain. Verify tracked files remain identical to the release commit after preparation and after builds; refuse publication if setup or build changes tracked source. Supply the private keystore and signing properties from the original checkout's `android-signing/` directory only to the isolated build, using restrictive temporary copies and cleanup; preserve the originals and never commit, log, or include secrets in assets. Reject stale or ambiguous files, missing outputs, duplicate names, invalid checksums, and unsigned APKs before any publication write.
- Record the expected APK signing certificate's SHA-256 fingerprint in tracked release configuration, separate from the gitignored private signing files. Establish it from the existing trusted signing identity, not automatically from whichever key is supplied during a release. Verify every release APK's valid signature and certificate against that fingerprint before any remote write; refuse missing or mismatched identities. Require explicit approval for an intentional fingerprint change, since a new key may prevent updates to existing installations.
- Create an annotated version tag that binds the release identity, push only that tag without force, create the notes-based Forgejo release, upload artifacts and checksums, and verify remote release metadata and asset bytes or independently verified digests against the manifest. Treat the Forgejo API's actual asset-verification capabilities as a prerequisite, not an assumption.
- Before any write, establish the deployed Forgejo release and asset API contract, including authenticated asset downloads and pagination. Restrict authenticated requests and redirects to trusted origins without forwarding credentials to other hosts, enforce bounded metadata and asset downloads, and hash downloaded bytes against the manifest. Refuse unsupported or ambiguous API behavior rather than assuming fake-service behavior applies to the live server.
- Reverify an existing complete release against its exact identity and assets. Refuse changed sources, targets, notes, settings, or conflicting evidence. For partial or uncertain remote writes, stop with inspection guidance; never delete assets, releases, or tags automatically, force-push, or blindly retry. Do not implement image promotion or package association for app artifacts.

### 3. Test the release workflow

- Add isolated tests using temporary repositories, fake build tools, and fake Forgejo/Git endpoints. Cover local validation and version mismatches, token security, clean and pushed source checks, target selection, artifact provenance, missing outputs, checksums, and duplicate names.
- Exercise successful publication and complete-release verification, exact-tag-only push, source and settings conflicts, pre-existing tags/releases/assets, concurrent execution, and failures or lost responses at every remote write. Assert no source push, unrelated tag push, automatic deletion, or secret disclosure occurs.
- Test each missing required format, stale build output, duplicate name, invalid APK signature, and absent signing material. Verify that `android-signing/` files are ignored and untracked, insecure permissions are refused, migration preserves the original key and refuses overwrites, and isolated-build cleanup leaves original secrets intact. Verify Android publication succeeds without an AAB and never builds or uploads one. Test every version mirror independently, canonical payload round trips, duplicate keys, malformed and noncanonical payloads, and exact identity mismatches.
- Test that tracked Android configuration survives preparation and builds unchanged and that tracked-file changes during either phase stop publication before remote writes. Test an APK with a valid signature from the wrong key, an absent expected fingerprint, and a matching certificate; confirm the expected fingerprint is never silently derived or changed from supplied signing secrets.
- Use realistic Forgejo API fixtures to test pagination, authenticated downloads, cross-origin redirects, oversized or malformed responses, missing and duplicate assets, and mismatched asset bytes. Local fakes cannot establish deployed API compatibility; record live compatibility as unverified unless separately approved and checked.
- Run the new tests, shell syntax checks, `--validate`, `npm test`, relevant app checks, and `git diff --check`. Record unavailable Android/desktop toolchains or live service checks rather than claiming they passed.

### 4. Update documentation

- Update `app/docs/forgejo-publishing.md`, `app/docs/release-builds.md`, and any README links to describe configuration, version and notes maintenance, token file, build and signing prerequisites, local validation, target selection, exact publication behavior, and recovery after uncertain writes.
- Update `app/docs/android-signing.md` to explain local `android-signing/` storage, permissions, legacy-key migration, isolated-build use, and encrypted off-device backups of the keystore and passwords. Warn that `.gitignore` is not encryption and does not untrack previously committed files. Document APK-only distribution without AAB or Google Play App Signing.
- Document how to establish the trusted public certificate fingerprint from the existing signing identity, its per-release verification, and the approval and update-compatibility implications of changing it. Explain that isolated builds preserve the tracked Android project and generate only documented ignored support files.
- Document that publication needs separate approval, a prepared toolchain and credentials, already-pushed `main`, and exclusive remote writers. Explain that local tests cannot prove live Forgejo permissions or device installation.

## Acceptance criteria

- App release configuration and version mirrors validate locally without credentials or network access, and mismatches fail clearly.
- Publication builds and verifies the selected app artifacts from the exact release source; tag, notes, targets, manifest, and remote assets agree.
- Android releases build and publish only a signed universal APK and its checksum. Signing secrets remain local in gitignored `app/android-signing/`, are never tracked or uploaded, and retain the existing key during migration.
- APK publication requires a valid signature from the configured expected certificate; isolated preparation and builds must not alter tracked Android source or configuration.
- Existing complete releases are verified rather than modified; partial or conflicting states stop without destructive cleanup or source pushes.
- Automated tests cover successful, conflicting, and uncertain paths without real publication. Documentation matches the implemented commands and limitations.
- Commit app changes in its repository and update the parent repository's app submodule pointer when implementing; do not modify implementation code as part of this plan.

## Risks and decisions

- Desktop and Android artifacts are not container images. Do not add server-only image promotion or package association.
- Signed Android builds may be nondeterministic and need local gitignored signing secrets. A retry must verify the original manifest and existing assets, not assume a rebuild produces identical bytes. Losing the keystore or passwords can prevent updates to existing installations; preserve encrypted backups outside the checkout.
- The critical review finding about an independent completed-release verification path remains unaddressed at the user's request; see `3-plan-review.md` before implementation.
- The current app publisher permits incremental target uploads and ancestor-tag resumes. Replacing these with a fixed release identity is an intentional compatibility change and must be documented.
- Existing release artifacts and tags may not carry the new identity. Refuse ambiguous legacy states and require separately approved manual investigation rather than rewriting history.
- Live publication, remote recovery, and installation checks require explicit approval and appropriate environments; simulated tests do not establish their success.
