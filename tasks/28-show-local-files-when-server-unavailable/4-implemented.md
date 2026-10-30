# implemented

- [Changes](#changes)
- [Safety decisions](#safety-decisions)
- [Verification](#verification)
- [Limits](#limits)

## Changes

- Created `28-show-local-files-when-server-unavailable` branches in the parent repository and `app/` submodule. The server submodule is unchanged.
- Added typed native request errors and a shared effective transport destination. Recognized connection failures switch both panes to local files while preserving the server URL and TLS preference; HTTP response errors and SSE-only failures do not switch stores.
- Added initialization and per-resource mutation readiness, synchronous context invalidation, local watcher rebinding, a fallback status, effective connection badges, and explicit same-URL reconnect. Use local files still clears the saved URL and selects deliberate local mode.
- Registered native local writes before dispatch and drained admitted operations before fallback reads, reconnect discovery, or data-directory changes. Pending local storage shows a waiting status; failed writes remain visible. Unrelated pending server requests do not delay local use, and obsolete completions cannot admit new backups.
- Split reconciliation into two-resource discovery followed by per-resource application. Discovery failure applies neither resource. Application failures retain partial/uncertain outcomes, stop further writes, and require Connect to recheck rather than replaying an uncertain action.
- Kept panes and drafts mounted through transitions. Protected note choices, IME, debounce/blur/pagehide saves, stale task IDs, edit/add drafts, and project operations. Initialization disables mutation controls but leaves dialog cancellation and settings usable. A retained add draft requires another submission to confirm its new destination.
- Added transport and real-app regression suites, extended native loopback error tests, and updated existing reconciliation expectations for discovery-before-write semantics. Updated both READMEs, server connection documentation, and live-sync documentation.
- Updated the client version from `0.15.23` to `0.15.24` in npm, Cargo, lockfiles, and Tauri configuration. Unrelated `todo.md` changes were not modified or staged.

## Safety decisions

- Addressed F1 with separate effective destination and mutation readiness. Public mutation entry points reject initialization-time writes even when callers capture a new context. Same-destination TLS replacement retains existing accepted snapshots and does not repeat startup reconciliation.
- Addressed F2 with an in-flight local-write barrier in the transport facade, not a new native serialization subsystem or offline upload queue. Tests defer the actual fake storage commit until the admitted operation settles. A never-settling native operation remains blocked; no timer grants false write authority.
- Addressed F3 with discovery-before-application and visible per-resource outcomes. Application remains nontransactional. Choosing the server strategy can intentionally adopt empty content; completed writes are not rolled back when a later operation fails.
- Dirty destination-transferred notes require an explicit choice. Dismissal retains the draft without saving, with a Review destination note action to reopen the choice. Failed server mutations are never redirected to local files.

## Verification

- `npm test` in `app/`: passed all 707 tests across 44 files, including 39 new fallback tests. Expected disk-full warnings come from deliberate backup-failure fixtures.
- `npm run build` in `app/`: passed TypeScript checking and the Vite production build for `0.15.24`.
- `cargo test -j 1` in `app/src-tauri/`: passed 62 tests; one existing opt-in real-server restart test was ignored. Binary and documentation test targets also passed.
- `cargo clippy --all-targets -j 1` in `app/src-tauri/`: passed without warnings.
- `git diff --check` in the parent and app repositories: passed.
- An earlier parallel native build encountered an LLVM linker segmentation fault. Serial native verification was rerun successfully, including the full test and Clippy commands above; no dependency or system changes were needed.

## Limits

- Desktop and Android manual interaction checks were not run in this session. Automated real-pane tests exercise the Tauri boundary with fakes; native loopback tests exercise actual request classification and timeouts.
- The opt-in real-server restart integration test remains ignored unless `MY_NTR_SERVER_BIN` is supplied. No external server mutation, deployment, or package installation was performed.
- Local files are the existing shared data-directory contents, not guaranteed current or per-server backups. Reconnect is explicit during fallback; there is no automatic merge, upload queue, or transactional rollback.
