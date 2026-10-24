# implemented

## changes

- Created fresh `15-server-live-update-recovery` branches in the parent and app repositories. Server implementation and `todo.md` remain unchanged.
- Added scoped native `server-live` events and connection ownership. Listener installation precedes connect; abort-aware setup and serialized lifecycle commands prevent stale subscriptions or cleanup from replacing or disconnecting a newer bridge. Local watcher events remain separate.
- The SSE bridge validates status/content type, reconnects after failures and closure, and detects silent streams. Defaults are a 15-second handshake deadline, 60-second inactivity deadline, and exponential retries from one to 30 seconds, resetting after a 30-second healthy stream. All incoming bytes, including heartbeat comments, reset inactivity. Disconnect cancels the stream and retries. Logs omit URLs, credentials, and response bodies.
- Every accepted connection refreshes both panes. Added per-resource single-flight recovery with coalescing, delayed retry of failed reads, cancellation, and a finite 30-second ordinary GET deadline. Recovery is event-triggered, not continuous polling; writes are never automatically retried.
- Focused clean notes now adopt incoming text with clamped logical selection preservation. Pending reconciliation blocks debounce, blur, and pagehide writes; updates during saves, reads, or IME composition drain safely afterward. Dirty and empty-note conflicts preserve local text and require an explicit choice. Failed saves retain their error without losing pending remote work.
- Added immutable transport contexts, synchronous settings activation, and local-directory generations. Old reads, save completions, label persistence, startup reconciliation, and conflict choices cannot initiate follow-up side effects against a new target. Dirty drafts survive target changes without implicit cross-server uploads. Closing settings without changing the target does not force a draft-transfer conflict.
- Added guarded task/label refreshes, independent read-error tracking, and task-derived label fallback without persisting incomplete remembered-label reads. Stale results cannot overwrite new-target state.
- Added frontend regressions for lifecycle ordering, StrictMode, focus/selection, conflicts, save/read overlap, empty notes, IME, transport changes, pending-read write guards, retries, and cancellation. A real-pane App integration test verifies independent task/note recovery when one initial reconnect GET fails and no later event arrives.
- Added native loopback, deterministic heartbeat/idle, cancellation, ownership, deadline, and reconnect tests. Added an opt-in real-server test using two independent native bridges and disposable files, without introducing a server dependency into the app's ordinary test suite.
- Added `app/docs/live-sync.md` and linked it from the feature list. Server APIs and last-write-wins semantics remain unchanged; collaborative merging and conditional writes remain outside scope.

## verification

- Final `npm test` in `app/`: passed, 436 tests across 33 files. Existing disk-full and failed-reconciliation fixtures emit their expected diagnostics.
- Final `npm run build` in `app/`: passed TypeScript and Vite production build at version `0.15.15`.
- `cargo test --locked` in `app/src-tauri/`: passed, 56 native tests plus binary/doc targets; one external-server integration test is intentionally ignored by default and was run separately below.
- `cargo clippy --all-targets --locked` in `app/src-tauri/`: passed without warnings. An earlier run found unchecked fixture read counts; the fixture now consumes complete request headers and the final run passed.
- `rustfmt --edition 2021 --check --config-path rustfmt.toml --config skip_children=true src/http.rs src/http_tests.rs src/state.rs src/lib.rs` in `app/src-tauri/`: passed.
- `cargo fmt --check` in `app/src-tauri/`: still reports existing four-space indentation in untouched `build.rs` and `src/main.rs`. No changed Rust file fails formatting; unrelated files were not reformatted.
- `cargo build --locked` in `server/`: passed with the existing server sources and lockfile. The server working tree remains clean.
- `MY_NTR_SERVER_BIN=/home/container/workdir/ntr/server/target/debug/my-ntr-server TMPDIR=/tmp/opencode cargo test --locked two_clients_sync_and_recover_missed_files_after_real_server_restart -- --ignored` in `app/src-tauri/`: passed. Two independent native bridges received A-to-B and B-to-A task/note mutations, both received closely spaced resource changes, and both automatically reconnected after an actual server process restart. Offline task/note file edits were fetched after recovery without a subsequent mutation. The test cleans up its server process and disposable data directory.
- Confirmed Axum `0.8.9`'s default `KeepAlive::new` interval is 15 seconds, below the client's 60-second inactivity deadline.
- `git diff --check` passed for app and parent changes. Release metadata agrees on `0.15.15`.

## verification limits

- Native transport and DOM behavior were verified, but two full desktop/mobile GUI instances were not manually exercised. `DISPLAY` is empty, no Wayland display is configured, and WebKitWebDriver is unavailable. Xvfb is available, but no GUI automation driver was installed or configured.
- Actual desktop/mobile focus, caret, IME, conflict gestures, physical network interruption, and deployment-specific reverse-proxy/TLS behavior remain manual checks. Native tests cover a real restart, connection refusal, stream errors, half-open inactivity, and heartbeat handling; they do not claim physical-device or proxy verification.
- No system packages or host configuration were changed. GUI verification needs an interactive session or a configured WebKitWebDriver/device environment.
- Writes already accepted by their original destination cannot be recalled or merged. Pending-read guards protect observable unsaved edits but do not provide server-side concurrency control.

## release and commits

- App version increased from `0.15.14` to `0.15.15` in npm metadata/lockfile, Cargo metadata/lockfile, and Tauri configuration.
- Tokio test features added two lockfile entries, `tokio-macros` and its `syn` dependency; existing dependency versions were not upgraded.
- App commit: `adcbc1b` — `Fix multi-client live updates and reconnect recovery`.
- App implementation is committed in its submodule. The parent records the updated pointer and this report. No publication, push, or merge is part of this step.
