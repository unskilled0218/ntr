# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Protected safety guidance](#protected-safety-guidance)
- [Delivery and limits](#delivery-and-limits)

## Changes

Shortened parent, app, and server READMEs and maintained topic pages. Removed duplicate feature history and obsolete format tutorials. Kept setup, editing, connections, HA management/recovery, development, signing, and publication in dedicated topics. The existing stack page was already concise and remains unchanged.

Existing app pages decreased from 7,988 to 3,429 whitespace-delimited words (57.1%). Existing server pages decreased from 7,618 to 3,969 words (47.9%). Counts exclude new release notes, historical records, and vendor content.

Prepared app `0.15.34` and server `0.2.15` with matching version mirrors, release pointers, and new documentation-only notes. Dependency versions and implementation remain unchanged.

The old server guide path remains only as an unlinked navigation stub for historical release links. Its format instructions and branding are gone. Maintained prose contains no old format branding or task-filename examples. Historical releases, archived tasks, vendor files, and package/source descriptions outside the documentation scope remain unchanged.

## Verification

- Temporary checker `/tmp/opencode/ntr-task40-doc-check.py`: passed 29 maintained pages, 183 local links, 27 historical release links, 17 shell blocks, TOCs/anchors, removed-branding checks, protected history/vendor content, archived tasks, and signing identity. Shell blocks were parsed with `bash -n`, not executed.
- App `./scripts/release.sh --validate`: passed offline version/configuration checks.
- App `npm run test:release`: all 52 tests passed, including signing-document guidance and the `trusted-certificate` anchor.
- Server `./scripts/release.sh --validate`: passed offline configuration checks. `TMPDIR=/tmp/opencode python3 -B -m unittest discover -s tests -p 'test*.py' -v`: 67 passed, one failed, no skips (68 tests, 1,034.929 seconds). The failure is `test_consumer_settings_version_notes_and_runtime_contract` at `tests/test_bash_release.py:197`, which hard-codes version `0.2.9` and its notes path. An isolated Git archive of unchanged baseline `a0b02a8` reproduces the same failure (`0.2.14` versus expected `0.2.9`). Tests remain unchanged under the documentation-only scope; this pre-existing stale assertion is not reported as a passing suite. Both Compose tests passed.
- Parent/app/server `git diff --check`: passed.
- Exact diff checks confirm every non-documentation edit is a version/release-pointer replacement. Runtime sources/tests, Compose, dependency versions, and the Android certificate fingerprint are unchanged.
- Existing app commit `7e32ad2` and server commit `a0b02a8` remain branch ancestors. The user's `todo.md` edit was neither changed nor staged.

## Protected safety guidance

- Retained loopback/no-auth exposure warnings, authenticating-proxy guidance, protected credentials, and verified HTTPS/WSS without bypasses.
- Checked Compose mounts, UID, dotenv behavior, and paths against `docker-compose.yml` and `.env.example`; no configuration changes were made.
- Retained HA admin opt-in, protected default lists, fresh empty-list checks, external-writer races, authoritative HA reconnect, and no automatic import/replay.
- Retained explicit move reconcile/abandon, schema migration backups, private sidecar ownership, Unix file/directory fsync limits, and uncertain-write inspection. Checked coordinator/request deadlines and response bounds against source.
- Retained remote-update approval, pending-note autosave restrictions, destination/save ownership, local-fallback limits, and last-write-wins warnings.
- Retained Android signing-key loss/update consequences, independently trusted fingerprints, private permissions, migration refusal rules, and encrypted off-device backups.
- Retained publication approval, clean/pushed-main prerequisites, writer exclusivity, supported association-version gates, trusted pins, at-most-one scoped link write/readback, and no destructive rollback or blind retry. Credential paths follow actual release configuration.

## Delivery and limits

Work uses fresh `40-clean-up-docs` branches in parent/app/server. Component commits precede the parent README/report/submodule-pointer commit. The app pointer includes the user's pre-existing signing fix without amending it.

No runtime JavaScript/Rust suites, builds, device checks, live HA checks, publication, association recovery, deployment, or push were performed. Runtime implementation and tests did not change. Release-tool publication messages came from hermetic fixtures, not real publication. This task prepares metadata only; it does not attest deployed compatibility or security.
