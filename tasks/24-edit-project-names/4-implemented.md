# Project name editing implementation

- [Project name editing implementation](#project-name-editing-implementation)
  - [Outcome](#outcome)
  - [Changes](#changes)
  - [Verification](#verification)
  - [Limits and decisions](#limits-and-decisions)
  - [Version and commits](#version-and-commits)

## Outcome

Implemented project renaming in local and server modes on newly created `24-edit-project-names` branches in the parent repository and `app/` submodule. The Project filter picker exposes Rename in normal and compact layouts. Renaming updates exact project tokens across active/completed tasks and remembered projects, follows the active source filter, and preserves unrelated task content and draft fields. The existing server API is unchanged. `todo.md`, the goal, the reviewed plan, and its review were not changed.

## Changes

- Added pure exact-token project rewriting and remembered-name transformation helpers. Names use existing validation and case-sensitive semantics. Unchanged names perform no writes; initial target collisions in tasks, remembered projects, or local draft/staged references are rejected rather than merged. Whitespace, similar project names, URLs, contexts, dates, tags, and legacy task prefixes are preserved by the transformation.
- Added a scoped operation helper with explicit phases, sequential task writes, acknowledged response provenance, uncertain-write verification, independent task/label progress, and explicit retry. Continuation checks recognize the operation's own target references without allowing unknown target tasks or unexplained label mixtures. Successful task writes remain applied after partial failure; retries skip acknowledged work and can finish labels alone.
- Added a native rename dialog with validation, progress, duplicate-submission protection, retained partial results, and an in-dialog Review update handoff. It closes native modality before remote approval, keeps progress outside dialog visibility, and never resumes writes merely because the result was reopened or remote content was approved. Closing a stopped result retains a Review rename progress control. Stop retry; keep partial changes provides an explicit way to abandon retry restrictions without implying rollback or authorizing a merge.
- Extended task writes with an explicit captured transport context and pre-dispatch validation for both native and HTTP paths. Follow-up reads/writes stop after transport, destination, or mount invalidation. Previously issued requests cannot be recalled; settled evidence remains associated with the original operation rather than granting authority over a replacement connection.
- Added awaitable, epoch-valid task checks to the approval coordinator. Rename and existing project removal validate between individual writes instead of treating their own delayed rescan as a foreign update. Own responses alone update the accepted projection; real foreign divergence stops stale-ID writes. Local watcher refreshes queue during a project operation and drain after it stops.
- Suppressed per-task label write-through during project operations. Final label persistence reads current remembered values, preserves unrelated projects/contexts, records the intended write, and verifies the observed outcome. Failed reads never become empty-label replacements. A verified intended result after an uncertain label response completes without another PUT. Suggestions retain unrelated task-derived projects after completion.
- Added one-shot destination-scoped draft mappings for selected, staged, and exact inline project references. Suspended edit drafts retain their fields and rebase only onto a matching verified task response. Partial operations block ambiguous source-project submissions until completion or explicit resolution. Local and server stale-edit guards reject unrelated task changes. Task operations do not resolve pending notes or resume conflicting note autosave.
- Closed compact Filter options as part of rename handoff so it does not keep remote approval behind an inert parent modal; preserved the established removal-prompt Options behavior. Added focus restoration to the normal/compact filter trigger and responsive rename-dialog/picker styling.
- Updated app/root READMEs and feature/live-sync documentation, and added dedicated `app/docs/project-renaming.md` covering use, partial progress, drafts, transport ownership, and concurrency limits.

## Verification

- `app/`: final `npm test` passed, **38 files and 582 tests**. Existing intentional backup/read-failure fixtures produced their expected warning output. The two added suites contain 25 pure/operation tests and 23 real-pane/transport tests; API and coordinator suites gained four additional tests.
- `app/`: final `npm run build` passed, including TypeScript checking and Vite production build.
- `app/src-tauri/`: `cargo test` passed, **60 tests**, with the real-server restart test ignored by default. `cargo clippy --all-targets` passed without warnings. Both commands compiled app version `0.15.20`.
- `app/src-tauri/`: `MY_NTR_SERVER_BIN=/home/container/workdir/ntr/server/target/debug/my-ntr-server TMPDIR=/tmp/opencode cargo test two_clients_sync_and_recover_missed_files_after_real_server_restart -- --ignored` passed separately, **one test**, using a real loopback server and disposable files.
- Tests cover exact tokens and metadata preservation, invalid/same/colliding names, remembered-only projects, multi-task completion, own-progress collision handling, partial-task and label-only retries, uncertain task/label writes, unrelated label additions, duplicate verification values, legacy-writer interference, destination/unmount invalidation, and same-destination TLS reconfiguration.
- Real-pane regressions cover normal/compact picker handoff, cancellation, active-filter migration, retained add and suspended edit drafts, partial-result reopening and explicit abandonment, delayed validation reads, duplicate submission, label failures, partial-write → remote-review → explicit-retry flow, and absence of unintended note writes while a dirty remote-conflicting note remains paused. Separate removal regressions verify delayed-rescan completion and stopping on genuine foreign ID reassignment without automatic replay.
- `git diff --check` passed in the parent and app before commits. Version checks confirmed agreement across npm/package lock, Cargo manifest/lock, and Tauri configuration. The server submodule has no changes; its full suite was not rerun because this implementation changes no server code or protocol.

## Limits and decisions

Manual desktop/Android and two-window UI acceptance were not performed in this headless container. Automated dialog/focus checks use the existing jsdom dialog shim; they do not establish actual device focus, touch behavior, accessibility-tree behavior, or real IME acceptance. The native restart test verifies transport recovery, not interactive project renaming across real devices.

Renaming uses existing individual task writes and whole-label replacement, not a transaction or compare-and-swap. Already issued writes and foreign writes between validation and persistence remain last-write-wins. Older clients can later restore cached source labels, and labels-only renames have no dedicated SSE notification. Verification establishes observed content, not author identity or a durable global rename invariant. Pending progress is retained only in the mounted pane, not across app restarts; documentation makes these limits explicit.

Explicitly stopping retry keeps partial persisted changes and releases draft restrictions; it does not roll them back or silently merge projects. This implements the plan's explicit-resolution path when unknown target references or changed evidence cannot safely be continued.

No dependencies were installed. No server endpoint, persistent alias registry, deployment, publication, tag, push, or live user-data migration was performed.

## Version and commits

- App version: `0.15.19` → `0.15.20`, synchronized in `package.json`, `package-lock.json`, `src-tauri/Cargo.toml`, `src-tauri/Cargo.lock`, and `src-tauri/tauri.conf.json`.
- App implementation commit: `f1687bf09b558c7537e17f370647c98e61bd32b8` (`feat: rename projects with scoped progress and safe retry`).
- Server remains at `06f28ab31b34c647bca216ced7e988184665ee69`, version `0.2.9`.
- The parent implementation commit records the app pointer, root README update, and this report. Both implementation branches are named `24-edit-project-names`; no branch was reused.
