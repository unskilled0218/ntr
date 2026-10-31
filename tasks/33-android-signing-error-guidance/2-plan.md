# plan

- [Scope](#scope)
- [Implementation plan](#implementation-plan)
  - [1. Add actionable fingerprint guidance](#1-add-actionable-fingerprint-guidance)
  - [2. Add focused regression tests](#2-add-focused-regression-tests)
  - [3. Update relevant documentation and version metadata](#3-update-relevant-documentation-and-version-metadata)
- [Acceptance criteria](#acceptance-criteria)
- [Risks and decisions](#risks-and-decisions)

## Scope

Improve missing Android signing certificate fingerprint messages in the app release workflow. Point users to the existing signing helper and setup documentation. Do not add another setup script, configure a certificate automatically, create or migrate keys, publish a release, or fix unrelated findings from task 32. This planning stage changes documentation only.

## Implementation plan

### 1. Add actionable fingerprint guidance

- In `app/scripts/release_publish.py`, define one small shared guidance string for missing fingerprint diagnostics. It must state that paths are relative to the app repository root, show `bash scripts/android-keystore.sh --fingerprint`, link by path to `docs/android-signing.md#trusted-certificate`, and name `android_certificate_sha256` in `scripts/release.json` as the setting to update after confirming the existing trusted signing identity.
- Append this guidance to the existing missing-fingerprint refusals in `build()` and `apk_check()` and the corresponding `--validate` warning. Preserve the existing diagnostic prefixes and success/failure behavior; the outer CLI handler must still print refusals to stderr and exit nonzero. `--validate` must still exit successfully for structurally valid configuration with an unset fingerprint while warning on stderr.
- Display instructions only. Do not invoke the signing helper, inspect signing files, run `keytool`, infer a trusted certificate, or change the configured fingerprint. Preserve the completed-release read-only path and all existing publication guards.

### 2. Add focused regression tests

- Extend `app/tests/test_release.py` to assert that both missing-fingerprint refusal paths contain the helper command, documentation path, configuration field, and app-root context. Mock tool availability where necessary so the `build()` test reaches the fingerprint guard without installing tools or invoking a build.
- Exercise the CLI refusal formatting and assert stderr contains the actionable guidance and the exit status remains nonzero, using isolated/mocked preflight rather than a real publication command. Verify the helper, subprocess build operations, and remote writes are not invoked after the missing-fingerprint guard.
- For the `--validate` warning test, explicitly supply a temporary configuration with a null fingerprint rather than depending on the real checked-in configuration remaining null forever. Assert success status, warning guidance on stderr, and no network or signing-key access. Retain coverage for configured fingerprints and completed-release verification without signing tools or keys.
- Run `python3 -B -m unittest discover -s tests -p 'test_release*.py' -v`, Bash syntax checks for the existing release/signing entry points, `bash scripts/release.sh --help`, `bash scripts/release.sh --validate`, and `git diff --check`. Never run no-argument publication against real services as a test.

### 3. Update relevant documentation and version metadata

- Add a short troubleshooting entry in `app/docs/android-signing.md` connecting the reported error to the existing fingerprint command and trusted-certificate setup. Explain that the command displays a public fingerprint but does not edit release configuration; preserve the distinction between migrating an existing key and explicitly creating a first key.
- Add a concise relevant note or link in `app/README.md`; keep detailed instructions in the dedicated signing document and maintain tables of contents for new headings.
- During implementation, follow the app's patch-version convention: advance `0.15.28` to `0.15.29` if still current, update all existing npm/Tauri/Cargo version mirrors, add matching release notes, update the configured notes path, and keep the README version/notes link consistent. Do not populate the private signing files or trusted fingerprint as part of this task.
- Commit app changes in its task branch, update the parent app submodule pointer, and record actual verification results in `4-implemented.md` under this task. Do not perform these implementation steps during planning.

## Acceptance criteria

- A missing Android fingerprint refusal shows the existing helper command and documentation path directly in the error output, with clear app-root context and the configuration setting to update.
- Local validation offers the same guidance without credentials, network requests, signing-key access, or behavior changes.
- Tests cover the diagnostic content, output stream/status, and absence of automatic setup or publication side effects.
- Documentation matches the existing helper and explains trusted-key confirmation without suggesting automatic replacement keys. Version mirrors and release notes remain consistent after implementation.

## Risks and decisions

- The fingerprint command requires existing prepared signing files and `keytool`; it is not a universal repair command. The documentation must remain the place to choose safe migration or first-time setup.
- Never suggest committing a keystore or password. Only the verified public certificate fingerprint belongs in tracked release configuration.
- This task improves discoverability, not the signing trust policy or release state machine. The three task-32 code-review warnings remain outside scope.
