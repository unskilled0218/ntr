# Implementation

- [Changes](#changes)
- [Verification](#verification)
- [Limits](#limits)
- [Repositories and version](#repositories-and-version)

## Changes

Added flushed `Release:` stage events on stderr for configuration, credentials, source checks, Forgejo preflight, isolated checkout setup, dependency installation, tests, combined builds, artifact/certificate validation, tag/release creation, and remote verification. Asset uploads and download verification identify validated names and inventory positions. Successful stages show elapsed seconds; final verified results remain on stdout after integrity checks. Existing releases explicitly announce read-only verification without builds, signing access, or remote writes.

Labeled setup/test/build commands now use private-file subprocess capture with monotonic deadlines and waiting events every 15 seconds. Raw stdout/stderr stays private on success and failure. Fixed tool labels, stage-aware failures, UTF-8 decoding, timeouts, and the 16 MiB accepted-output limit are retained. Timeout, interruption, or polling failure kills the command's process group and reaps the direct child. Ctrl+C exits with status 130 and preserves partial-state warnings. Added standalone desktop/Android start and completion markers without changing the combined build invocation or artifact requirements.

Updated relevant app and parent READMEs, publishing/build documentation, and app release notes. No UI, server, release identity schema, credential configuration, target selection, retry policy, or rollback policy changed.

## Verification

- `python3 -B -m unittest discover -s tests -p 'test_release*.py' -v` in `app`: passed all 52 tests on the final implementation. Added coverage for ordered publication/read-only logs, real redirected live output before completion, controlled 15-second waiting cadence, quiet commands, machine-readable input/output, secret withholding on both streams, unavailable tools, invalid labels, output limits, invalid UTF-8, failed uploads, private remote errors, timeout/interruption process-group cleanup, and standalone target markers. Existing partial-state and no-retry contracts still pass. Detailed local output: `/tmp/opencode/ntr-34-release-tests.log`.
- `bash -n scripts/release.sh` and `bash -n scripts/build-release.sh` in `app`: passed.
- `bash scripts/release.sh --help` in `app`: passed without publication progress or execution.
- `bash scripts/release.sh --validate` in `app`: passed local configuration and version-mirror checks without credentials or network.
- Additional local checks: version `0.15.30`, matching release notes, preservation of the pre-existing trusted certificate, and relative links in changed app documentation passed.
- `git diff --check` in both app and parent repositories: passed.

## Limits

Progress events intentionally do not expose raw compiler/test diagnostics. The combined publisher build lists selected targets rather than claiming a current target. Only dependency installation, tests, and combined builds emit periodic waiting events; other operations announce starts and completions. Waiting messages do not prove forward progress or estimate completion.

Process-group cleanup stops descendants that remain in the launched command's group; tools that deliberately detach into another session are outside that mechanism. The direct child is reaped; killed grandchildren can briefly remain as zombies until their system reaper collects them. The captured-output limit is checked at waiting intervals and after completion, not enforced as a disk quota.

No real publication, production API call, remote push, dependency installation, signing, full native build, or interactive device test was performed. Build/publication tests use fake tools and services with temporary local Git repositories. Frontend and Rust application suites were not rerun because implementation changes are limited to release tooling and metadata.

## Repositories and version

Created fresh branches named exactly `34-display-app-release-logs` in the parent and app repositories. Prepared app `0.15.30` across npm, Cargo, Tauri, release configuration, and release notes; it is not published. The server is unchanged. The pre-existing app commit `94d69e6` and its configured certificate are preserved. `todo.md` remains untouched and excluded from commits.

App implementation commit: `841a7e3` (`Add credential-safe release progress logs in app 0.15.30`). The parent implementation commit records this report, its README update, and the new app submodule pointer.
