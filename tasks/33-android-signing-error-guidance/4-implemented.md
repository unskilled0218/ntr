# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Limitations](#limitations)
- [Commits](#commits)

## Changes

- Created new `33-android-signing-error-guidance` branches in the parent repository and app submodule.
- Added shared missing-fingerprint guidance to both Android refusal paths and the local-validation warning in `app/scripts/release_publish.py`. Messages identify the app repository root, `bash scripts/android-keystore.sh --fingerprint`, `docs/android-signing.md#trusted-certificate`, and `android_certificate_sha256` in `scripts/release.json`.
- Preserved the diagnostic prefixes, signing trust policy, publication guards, refusal status, and successful `--validate` status. Extracted the existing outer error handling into `cli()` so its stderr and exit-status behavior can be tested without live preflight.
- Added five focused tests for build/APK refusals, subprocess CLI refusal formatting/status, temporary null-fingerprint validation, and configured-fingerprint validation. Tests prohibit setup tools, secret access, and API adapter construction in the diagnostic paths; existing completed-release read-only regression coverage remains intact.
- Added signing-error troubleshooting documentation and a relevant README link. Bumped all app version mirrors to `0.15.29`, added matching release notes, and updated the configured notes path.

## Verification

- Passed: `python3 -B -m unittest discover -s tests -p 'test_release*.py' -v` — 41 tests, including the five new focused tests and existing release-state regressions.
- Passed: `npm run build` — TypeScript and Vite production frontend build.
- Passed: Bash syntax checks for `scripts/release.sh`, `scripts/build-release.sh`, and `scripts/android-keystore.sh`.
- Passed: `bash scripts/release.sh --help` and `bash scripts/release.sh --validate`. Validation exits successfully, checks matching version metadata, and prints the new unset-fingerprint guidance to stderr without credentials or network access.
- Passed: app staged `git diff --check`; parent `git diff --check` before the implementation commit.

## Limitations

- No keys were created, migrated, inspected, configured, or uploaded. The actual signing helper was not invoked; tests use dummy signing inputs and simulated API/build operations where required by existing fixtures.
- `android_certificate_sha256` remains unset. The improved message explains the setup requirement; it does not bypass it or establish a trusted certificate.
- No actual release was published or pushed. Live Forgejo, real Android signing/device behavior, and desktop bundling were not tested for this diagnostic-only task.
- Task 32's three unresolved code-review warnings remain outside scope. No release-state, artifact-retention, or source-identity fixes were made.

## Commits

- App implementation: `54fe677` (`Add actionable Android fingerprint error guidance`).
- The parent implementation commit records this report and updates the app submodule pointer.
