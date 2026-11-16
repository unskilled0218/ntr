# Implemented

- [Changes](#changes)
- [Verification](#verification)
- [Limits](#limits)

## Changes

- Completed goal, plan, plan review, plan update, and implementation for task 38. Created fresh `38-ha-review-warnings` branches in the parent and server; the app branch and pointer remain unchanged.
- Fixed task 37 review F1: retain an author origin only when both the expected task snapshot and the published catalog match. Concurrent external empty-list rename/create/remove events reach the author; self-only writes remain filtered and unchanged later polls stay silent.
- Fixed review F2: HA sidecar saves now write and synchronize the temporary file, rename it, then synchronize the parent directory before admitting dependent HA mutations. Schema migration and all journal/identity/recovery transitions use this writer. File-backed tasks, Markdown notes, and labels keep the existing atomic writer.
- Added private per-call/per-store persistence seams and deterministic failures at write, file sync, rename, and directory sync. Regression tests cover migration failure, move admission, verified-target persistence, completion, and reconcile/abandon, including post-rename disk/memory divergence without unsafe deletion or replay.
- Updated the server README, HA durability/storage guidance, live-update provenance docs, development checks, and release notes. Server version and mirrors are `0.2.13`; updated the release-notes pointer to the new notes. App version stays `0.15.32`. Server implementation commit: `8218192`.
- Preserved existing uncommitted `app/package-lock.json` edits. Did not modify `todo.md` or earlier task records.

## Verification

| Check | Result |
| --- | --- |
| Server locked tests | Passed: 60 library tests and 22 separate integration tests, 82 total. Includes eight new test functions plus parameterized cases for both reviewed warnings. |
| Server `cargo fmt --check` | Passed. |
| Server `cargo clippy --locked --all-targets -- -D warnings` | Passed. |
| App `npm run test:ha-contract` against server `0.2.13` | Passed with the real serializer/server and disposable generated-CA HTTPS/WSS fixture. |
| Server Compose rendering test | Passed: one configuration test; no container started. |
| Server `./scripts/release.sh --validate` | Passed offline without credentials or remote operations. The initial check found an inherited old release-notes pointer; updating it to `docs/releases/0.2.13.md` resolved the failure. |
| Version mirrors and Git whitespace checks | Passed. |

Rust commands used `CARGO_TARGET_DIR=/tmp/opencode/ntr-task38-target`; fixture runs used `TMPDIR=/tmp/opencode`. Frontend implementation and native app code are unchanged, so full frontend/native desktop suites were not rerun in this task. The real client/server contract was rerun against the changed server.

## Limits

HA sidecar persistence requires Unix and filesystem/storage semantics that honor file and directory synchronization. Unsupported platforms and sync failures return errors rather than silently reducing durability. Network/virtual filesystems and hardware that ignores flush requests need operator validation. A post-rename failure can expose the new sidecar while retaining conservative pending state in memory; explicit recovery remains required for uncertain moves.

Tests inject deterministic persistence errors and restart the store; no physical power-loss test was performed. HA operations remain nontransactional, and the documented exclusive-external-writer requirement still applies. No live HA operations, private deployment credentials, dependency installation, container startup, publication, deployment, or push was performed.
