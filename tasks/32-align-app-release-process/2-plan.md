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

## Implementation plan

### 1. Define the app release contract

- Inspect `server/scripts/release.sh`, its helpers, tests, and release documentation for the applicable source, authentication, validation, locking, and retry rules. Adapt them for artifacts rather than copying image or package-association operations.
- Add app release configuration equivalent to `server/scripts/release.json`, identifying the Forgejo repository, username, private token file, release notes, and supported artifact targets. Define a canonical app version and validate `package.json`, `package-lock.json`, `src-tauri/tauri.conf.json`, `src-tauri/Cargo.toml`, and the app entry in `src-tauri/Cargo.lock` against it.
- Add versioned release notes with the server's `# Release v<version>` convention. Bind the release identity to the exact source commit, relevant configuration, scripts, notes, selected targets, and an artifact manifest containing names and SHA-256 digests.
- Specify desktop and Android target selection, expected artifact types, unique asset names, and checksum files. Keep the existing build entry point usable, but never assume files already in `release/<version>/` came from the current source.

### 2. Implement guarded publication

- Replace `app/scripts/release.sh` with a server-style entry point supporting `--help`, credential-free and network-free `--validate`, and an explicitly documented publication mode. Preserve desktop and Android selection with a clear, immutable target set per release.
- Require a clean, already-pushed `main`, matching configured fetch and push destinations, normal TLS verification, validated private token-file ownership and permissions, necessary tools, and exclusive local execution. Do not push source or unrelated tags; do not accept legacy token-value or endpoint overrides silently.
- Run applicable app tests and build the selected targets from the verified commit in a clean, isolated output location. Reject missing expected outputs, stale or ambiguous files, duplicate names, and invalid checksums before any publication write. Ensure Android signing requirements are checked without exposing secrets.
- Create an annotated version tag that binds the release identity, push only that tag without force, create the notes-based Forgejo release, upload artifacts and checksums, and verify remote release metadata and asset bytes or independently verified digests against the manifest. Treat the Forgejo API's actual asset-verification capabilities as a prerequisite, not an assumption.
- Reverify an existing complete release against its exact identity and assets. Refuse changed sources, targets, notes, settings, or conflicting evidence. For partial or uncertain remote writes, stop with inspection guidance; never delete assets, releases, or tags automatically, force-push, or blindly retry. Do not implement image promotion or package association for app artifacts.

### 3. Test the release workflow

- Add isolated tests using temporary repositories, fake build tools, and fake Forgejo/Git endpoints. Cover local validation and version mismatches, token security, clean and pushed source checks, target selection, artifact provenance, missing outputs, checksums, and duplicate names.
- Exercise successful publication and complete-release verification, exact-tag-only push, source and settings conflicts, pre-existing tags/releases/assets, concurrent execution, and failures or lost responses at every remote write. Assert no source push, unrelated tag push, automatic deletion, or secret disclosure occurs.
- Run the new tests, shell syntax checks, `--validate`, `npm test`, relevant app checks, and `git diff --check`. Record unavailable Android/desktop toolchains or live service checks rather than claiming they passed.

### 4. Update documentation

- Update `app/docs/forgejo-publishing.md`, `app/docs/release-builds.md`, and any README links to describe configuration, version and notes maintenance, token file, build and signing prerequisites, local validation, target selection, exact publication behavior, and recovery after uncertain writes.
- Document that publication needs separate approval, a prepared toolchain and credentials, already-pushed `main`, and exclusive remote writers. Explain that local tests cannot prove live Forgejo permissions or device installation.

## Acceptance criteria

- App release configuration and version mirrors validate locally without credentials or network access, and mismatches fail clearly.
- Publication builds and verifies the selected app artifacts from the exact release source; tag, notes, targets, manifest, and remote assets agree.
- Existing complete releases are verified rather than modified; partial or conflicting states stop without destructive cleanup or source pushes.
- Automated tests cover successful, conflicting, and uncertain paths without real publication. Documentation matches the implemented commands and limitations.
- Commit app changes in its repository and update the parent repository's app submodule pointer when implementing; do not modify implementation code as part of this plan.

## Risks and decisions

- Desktop and Android artifacts are not container images. Do not add server-only image promotion or package association.
- Signed Android builds may be nondeterministic and need external secrets. A retry must verify the original manifest and existing assets, not assume a rebuild produces identical bytes.
- The current app publisher permits incremental target uploads and ancestor-tag resumes. Replacing these with a fixed release identity is an intentional compatibility change and must be documented.
- Existing release artifacts and tags may not carry the new identity. Refuse ambiguous legacy states and require separately approved manual investigation rather than rewriting history.
- Live publication, remote recovery, and installation checks require explicit approval and appropriate environments; simulated tests do not establish their success.
