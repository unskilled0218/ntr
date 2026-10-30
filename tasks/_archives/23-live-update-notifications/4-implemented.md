# Implementation

- [Implementation](#implementation)
  - [Outcome](#outcome)
  - [Changes](#changes)
  - [Verification](#verification)
  - [Limits](#limits)
  - [Versions and commits](#versions-and-commits)

## Outcome

Implemented approval-based remote task and note updates. Continued on the existing `23-live-update-notifications` branch as requested, including in both Git submodules. Preserved the unfinished native/server origin-filtering work and repaired its truncated Rust expressions and NUL padding. `todo.md`, the goal, and the reviewed plan were not changed.

## Changes

- Added a remote-update coordinator as the authority for accepted snapshots, pending/deferred offers, mutation epochs, read generations, and immutable application tokens. Detection reads do not paint panes or write backups. Application acknowledgment validates and commits synchronously; failed, superseded, dirty-draft, and IME-deferred applications remain unresolved.
- Changed server SSE signals and reconnect recovery to detect content without adopting it. Initial reads close the event/loading race. Replacement transports preserve same-destination approval state and invalidate obsolete work. Unmount cleanup prevents late save settlement from restarting detection.
- Added a native in-app Update / Not now dialog and persistent Review update controls. Task and note offers queue behind settings, startup conflicts, and other dialogs. Dismissal, Escape, and backdrop actions do not upload content. Identical declined snapshots remain reviewable without a new event.
- Paused note autosave, blur, pagehide, and follow-up saves while remote divergence is unresolved. Dirty drafts retain the explicit Keep mine / Use theirs choice after notification approval; runtime version-choice dismissal is read-only. Kept single-flight destination save ownership, baseline-return and empty drafts, undo/history, IME protection, transport-scoped save provenance, and logical selection restoration.
- Made task filtering and sorting derive from the accepted unfiltered snapshot. Own mutations project returned tasks or targeted deletions, without adopting unrelated list changes. Label suggestions use known tasks and deliberate remembered-label updates. Unsafe task-ID actions reopen review without replaying the old action. Review can suspend an edit dialog without clearing its fields; stale or different-destination edit actions cannot save through the old identity.
- Separated destination identity from connection generation. Unchanged settings do not replace the subscription, reload panes, or reconcile files. Same-URL certificate changes detect without startup write-through under `ask`, `server`, and `local`. First initialization and actual destination changes retain startup reconciliation and draft-safe handoff.
- Added one random session-origin ID to native server mutation requests and SSE handshakes, distinct from per-subscription connection IDs. The server filters matching-origin events, preserves legacy event names and payloads, and delivers watcher/foreign events normally. Broadcast lag emits both existing resource tokens before buffered events, bypassing origin filtering and retaining the queued second signal across polls.
- Scoped task mutation backups to their original transport, preventing late responses from backing up another destination. Updated component/root READMEs, client feature/live-update documentation, server API/live-update documentation, release notes, and release-configuration mirrors.

## Verification

- `app/`: `npm test` passed: 36 files, 530 tests. Expected warning output comes from deliberate backup/read-failure fixtures. After the final task destination guard, the focused TodoPane, remote-approval, and remote-dialog suites also passed: 3 files, 38 tests.
- `app/`: `npm run build` passed after the final code changes: TypeScript checking and Vite production build succeeded.
- `server/`: `cargo test` passed: 25 unit tests, 14 API integration tests, and 3 task-date integration tests; no failures.
- `server/`: `cargo clippy --all-targets` passed without warnings. `cargo build` also passed.
- `app/src-tauri/`: `cargo test` passed: 60 tests; the real-server restart test is ignored by default and was run separately below.
- `app/src-tauri/`: `cargo clippy --all-targets` passed without warnings on retry. The first attempt hit rustc 1.99.1's `Missing SyntaxContext 17018 for crate "icu_normalizer_data"` cache panic. `cargo clean -p icu_normalizer_data` removed only generated artifacts for that dependency; both Clippy and native tests then passed. No packages were installed.
- `app/src-tauri/`: `MY_NTR_SERVER_BIN=/home/container/workdir/ntr/server/target/debug/my-ntr-server TMPDIR=/tmp/opencode cargo test two_clients_sync_and_recover_missed_files_after_real_server_restart -- --ignored` passed: 1 test. This uses two native bridges and a real loopback server restart with disposable files.
- Coordinator/real-pane regressions cover deferred review, read/application failures, duplicate choices, newer snapshots, empty notes, deleted/reassigned tasks, pre-write GET invalidation, concurrent foreign writes, uncertain writes, in-flight PUTs, baseline-return drafts, IME deferral, stale version choices, retained task drafts, task filters and own mutations after decline, delayed initialization, reconnect, and equal-content lag rescans. They assert visible content and absence of unintended writes.
- Settings regressions verify read-only unchanged settings and same-destination TLS replacement under all three startup conflict strategies, plus write-through reconciliation on actual destination changes.
- Server regressions cover every task/raw/note mutation, two identified subscribers, legacy subscribers, absent IDs, watcher events, and deterministic repeated lag with a lost foreign event followed by more than the 16-event channel capacity of self-events. Native regressions check mutation/handshake headers while retaining cancellation, reconnect, TLS-policy, and listener-ownership coverage.
- `server/`: `./scripts/release.sh --validate` passed: configuration valid, no credentials or remote operations used. `python3 -B -m unittest discover -s tests -p 'test*.py' -v` also passed: 66 release-tooling tests in 1001.390 seconds, using disposable repositories and fake external-service ports.
- `git diff --check` passed in the parent and both submodules before their commits.

## Limits

Manual two-window desktop/mobile checks were not performed in this headless container. Native dialog focus/backdrop behavior on real devices, touch dismissal, selection rendering, real IME interaction, and reverse-proxy behavior still need manual acceptance. Automated native bridges do not replace those UI checks.

Storage remains last-write-wins. Already-issued writes and post-validation task races can overwrite concurrent changes; this task adds neither transactional compare-and-swap nor revision history. Precise self-event filtering requires the updated server. Older servers retain snapshot comparison and the approval boundary, without reliable author attribution. Legacy clients may automatically refresh both resources after lag.

## Versions and commits

- App version: `0.15.18` → `0.15.19`; npm/package lock, Tauri configuration, Cargo manifest, and Cargo lock agree. Commit: `cb617f864b9e478b35e9c9096abfdef6b158b447` (`feat: require approval for remote task and note updates`).
- Server version: `0.2.8` → `0.2.9`; canonical `VERSION`, Cargo manifest/lock, README, release configuration, and release notes agree. Commit: `06f28ab31b34c647bca216ced7e988184665ee69` (`feat: filter self-originated events and recover broadcast overflow`).
- The parent implementation commit records both submodule pointers, the root README update, and this implementation report. No tags, pushes, publication, or live deployment were performed.
