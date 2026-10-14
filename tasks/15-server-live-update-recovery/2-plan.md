# plan

## scope

Implement `1-goal.md` in the `app/` submodule. Preserve the server endpoints, SSE resource tokens, last-write-wins persistence, certificate policy, and local-only behavior. No server production changes, collaborative merging, or unrelated refactoring are planned. Do not touch `todo.md`.

This document is the planning-stage deliverable. Do not modify implementation code or versions in this stage. Later implementation should record results in `4-implemented.md`, follow the implementation workflow's version and commit conventions, and update the parent repository's app submodule pointer only after committing app changes.

## current behavior

- `NotePane.tsx` ignores clean focused-note events and discards reconciliation requests during saving. `adoptNote` does not restore selection. Truthy checks on `noteConflict.current` fail for an empty remote note.
- `http.rs` opens one SSE request and exits on failure or closure. It forwards server tokens on the same unscoped Tauri event used by the local watcher.
- `state.rs` stores only a task handle. Connect aborts and replaces that handle in separate lock operations; disconnect has no subscription identity.
- `api.ts` starts the bridge before installing its listener. `App.tsx` asynchronously receives its cleanup function, so StrictMode cleanup or settings changes can happen before setup completes. `main.tsx` enables StrictMode.
- `TodoPane.tsx` refreshes tasks and labels independently. Reads can overlap, so older responses must not undo a newer recovery refresh.
- Existing caret helpers already capture and restore logical selection offsets. Existing API and note tests mock transport boundaries; native SSE tests currently cover token parsing only.

## implementation plan

### 1. Define an owned, client-internal live subscription

- Keep local `watch.rs` emitting `change` with string payloads unchanged. Introduce a separate native server event, such as `server-live`, with a serializable `{ connectionId, kind }` payload. Allowed kinds are `connected`, `tasks`, and `note`; the server still sends only its existing resource tokens.
- Generate a unique connection ID in `api.ts` before installing listeners or invoking native connect. Pass it to `server_connect` and `server_disconnect`. Capture URL and certificate settings once per subscription rather than rereading them after awaits.
- Replace `AppState.sse_task` with one mutex-protected optional owned connection containing its ID and task handle. Build the HTTP client before taking this mutex. Abort the previous task and install its replacement in a single critical section; do not hold the mutex across network awaits.
- Make disconnect idempotent and conditional on the supplied ID matching the current owner. A delayed cleanup for A must not abort B. Every emission includes its originating connection ID so buffered events from A cannot be mistaken for B.
- Keep ownership helpers small and testable independently of `AppHandle`. Update comments and mirrored TypeScript/Rust event definitions together. Do not change HTTP server request or response DTOs.

### 2. Make the native SSE bridge reconnect and announce recovery

- Extract the SSE transport loop behind an event-emission callback so native tests can exercise real requests without constructing a Tauri GUI. Retain `sse_tokens` as the existing parsing seam.
- Loop over connection attempts until the owned task is aborted. Validate successful HTTP status and an SSE-compatible content type before announcing `connected` or interpreting tokens. Treat refused connections, failed handshakes, unsuccessful responses, stream errors, and EOF as retryable failures.
- Emit `connected` after each accepted stream response, including the first connection, before forwarding resource events. The server has already established its subscription at this point; frontend recovery reads can catch changes missed before subscription.
- Use bounded exponential backoff, starting at one second and capping at 30 seconds. Prevent immediate-open/immediate-close responses from resetting the delay indefinitely: reset after a sustained healthy stream, not merely successful headers. Clear the parsing buffer for every new response and forward only `tasks` and `note`.
- Bound connection establishment with a finite header/handshake deadline, for example 15 seconds, while leaving an established SSE stream long-lived. Do not add a total request timeout to the cached client that would periodically terminate healthy streams.
- Aborting the task must cancel both active requests and retry sleeps. No detached retry tasks should survive disconnect or reconfiguration. Keep certificate validation behavior supplied by `client_for` unchanged.
- Log actionable connection failures without response bodies, credentials, or sensitive URLs. Do not add a new connection-status UI in this task.

### 3. Install listeners first and control asynchronous lifecycle ordering

- Extend the existing `onChange` seam with an optional abort signal and a reconnect callback, retaining resource callbacks for normal changes. `App.tsx` should create an `AbortController` for each effect and abort it synchronously during cleanup, including when setup has not resolved.
- In server mode, register the scoped `server-live` listener before invoking connect. Ignore events when aborted, superseded, or carrying another connection ID. Ignore local watcher events in server mode; local backups must not masquerade as server changes.
- Give subscriptions a module-local generation and serialize native lifecycle transitions through a small promise queue. Recheck generation and abort state after listener registration and immediately before a queued connect. An older delayed setup must not start after a newer subscription; a connect already issued must finish before the next queued connect starts. Ensure rejected operations do not poison the queue.
- Cleanup should immediately disable callbacks, remove listeners once available, and request only its own scoped disconnect. If abort occurs during an issued connect, enqueue scoped teardown when that connect finishes. Make repeated cleanup harmless and remove listeners on setup failure.
- On a switch to local mode, invalidate old server callbacks and queue owned teardown before continuing local event delivery. Local subscriptions should continue using the original string event and never start an SSE bridge.
- Handle setup rejection in `App.tsx` instead of leaving an unhandled promise. Network failures are handled by the native retry loop; command/listener setup failures should be logged through the existing warning pattern.
- Map `connected` to `refreshPanes()` so both resources are read on initial connection and every reconnect, even if no new mutation follows. Do not rerun `reconcileWithServer` or upload stale local backups on reconnect; recovery reads use current server state and note conflict handling.

### 4. Reconcile note updates without losing local input

- Remove the focused-clean early return. Capture a focused editor's logical selection with `getCaretRange` immediately before adopting remote text. Restore it with `setCaretRange`, clamping to the new text length, then update edit-line markup. Do not steal focus from another control or reset selection on no-op/in-sync responses.
- Preserve the existing clean/adopt, in-sync/rebase, and dirty/conflict policy in `classifyNoteEvent`. Keep history reset on remote adoption; no character-level text merge is introduced. When offsets cannot represent the original logical location, retaining clamped offsets is the defined fallback.
- Introduce a pending reconciliation flag and a single-flight read/drain path. Events during saving, composition, or an existing read should mark pending rather than disappear. Coalesce duplicate events but guarantee another read if an event arrives while a read is underway.
- Route initial loading, live events, and focus checks through guarded read logic so a late initial response cannot erase edits or overwrite newer reconciliation. Snapshot an edit/save revision and transport epoch for each read; discard stale results and retain pending work when a save or transport switch invalidates the result. Read current editor text after the await before classifying.
- In `flushNote` completion, clear the saving flag before draining pending reconciliation. Await that drain before rearming autosave for text entered during the PUT. A pending remote conflict must be established before another automatic write can overwrite it. Run the drain after failed saves as well, while retaining the existing save error and dirty input.
- While IME composition is active, do not repaint, open a dialog, or save transient preedit. Drain pending remote work after composition ends, before a follow-up autosave writes the finalized text.
- Use `noteConflict.current !== null` consistently in save, reconciliation, resolution, and page-close guards. An empty string is a valid remote version. While a conflict is open, new remote reads may update its incoming text without reopening the dialog; preserve the user's local version and block saves until resolution.
- After conflict resolution, process deferred work without duplicating the chosen write. Preserve explicit Keep mine and Use theirs semantics; do not claim protection against server writes that race after the user's choice.
- Cancel timers and invalidate async continuations on unmount, including StrictMode remounts. A pending pagehide beacon must not write through an unresolved conflict or active composition.

### 5. Prevent stale recovery reads from winning

- Thread the existing `connectionKey` into pane read ownership, or introduce an equivalent narrowly scoped transport epoch shared with the subscription lifecycle. Invalidating the epoch must prevent an old server/local read from applying to the new mode.
- In `TodoPane.tsx`, use request generations for task refresh and label loading so an older response cannot overwrite a newer list, label set, or error. Guard the derived-label persistence path against an obsolete transport before invoking `putLabels`.
- Keep task and note refreshes independent. Coalescing is per resource, not one global busy flag that drops the other resource. Retain the existing task filters and label behavior.
- Add only the read ownership needed for initial/reconnect/live refresh safety. Do not redesign settings, storage reconciliation, or mutation APIs.

### 6. Add focused regressions at existing seams

- Extend `NotePane.test.tsx` with focused clean adoption, collapsed caret and selection preservation, shorter/empty remote text, no-op selection preservation, dirty conflicts with empty/nonempty remote text, and both conflict choices.
- Use deferred `getNote`/`putNote` promises and fake timers to test events during successful and failed saves, additional typing during a save, save/read overlap, a second event during a read, remote updates while a dialog is open, IME deferral, stale initial loads, transport switches, and unmount cleanup. Assert editor contents and writes, not only callback counts.
- Extend `noteSync.test.ts` with empty-string verdict cases. Reuse current caret tests rather than duplicating the caret implementation.
- Extend `api.test.ts` to assert listener-before-connect ordering, captured settings, scoped IDs, immediate abort during pending listener/connect setup, setup failure cleanup, stale cleanup after replacement, local/server mode switches, old-ID event rejection, recovery callbacks, and independent task/note delivery from one event burst.
- Add `App.test.tsx` with lightweight pane handles and a mocked subscription seam to assert that `connected` refreshes both panes without a following change event. Exercise StrictMode setup/cleanup and settings re-subscription; verify failures do not create unhandled rejections.
- Add focused TodoPane regressions, using the existing suite if present, to resolve refresh promises out of order and verify that only current request/transport results apply.
- In native tests, drive the extracted bridge against a disposable loopback HTTP/SSE fixture. Cover connection refusal followed by recovery, unsuccessful HTTP status, invalid content type, EOF and stream error recovery, multiple/split task-note frames, recovery notification ordering, buffer reset, bounded backoff, and task cancellation during a request and retry delay.
- Test ownership separately: disconnect A after replacement by B leaves B running; disconnect B stops it; replacement aborts the old task. Use a bounded timeout for every async assertion.
- Add only the required Tokio dev features for loopback fixtures and deterministic paused-time tests in `src-tauri/Cargo.toml`, such as `macros`, `rt`, `net`, `io-util`, and `test-util`. Avoid new runtime frameworks or production retry dependencies. Update the lockfile only if dependency resolution requires it.

### 7. Verify and document the behavior

- From `app/`, run `npm test` and `npm run build`. From `app/src-tauri/`, run `cargo fmt --check`, `cargo test`, and `cargo clippy --all-targets`. Record exact commands and outcomes in the implementation report; planning does not rerun or claim these checks.
- If Linux Tauri dependencies or tools are unavailable, report the missing prerequisites to the user. Do not install packages or use privileged commands. Mark native tests and GUI checks unavailable rather than substituting a token-parser test for reconnect coverage.
- Use a disposable server data directory and two independent client instances/profiles. Check A-to-B and B-to-A task and note changes, focused clean-note updates, dirty-note conflict choices, empty remote notes, and closely spaced changes to both resources.
- Disconnect one client, change both resources from the other, and restore connectivity. Verify both panes recover automatically without another mutation. Separately restart the server and verify both clients recover. Confirm replacing settings during retry stops contacting the old server.
- Document automatic reconnect and last-write-wins limits in a dedicated `app/docs/live-sync.md`, link it from the existing feature entry, and keep the README brief. Clarify that same-note concurrent saves can still overwrite each other; conflict detection is not server-side concurrency control.

## acceptance criteria

- Both resources synchronize bidirectionally across two server-connected clients without restart, settings changes, or a focus cycle.
- Clean focused notes adopt updates while preserving focus and a clamped logical selection; dirty notes retain local input and use explicit conflict choices, including empty remote notes.
- Events received during a save, composition, or read remain pending until safe reconciliation; stale reads cannot erase newer input or new-transport state.
- The bridge retries failed connections, bad responses, errors, and closure with bounded backoff. Disconnect/replacement cancels active work and retries.
- Listener ordering, scoped ownership, lifecycle serialization, and abort-aware setup prevent older subscriptions from replacing or disconnecting the current one.
- Every accepted connection refreshes tasks and notes, including missed offline changes without a subsequent event. Old local backups are not pushed merely because the stream reconnects.
- Automated tests exercise behavioral regressions and native recovery paths; implementation records actual two-client results or explicit environment blockers.
- Existing server contracts, local-only events, certificate policy, labels, and last-write-wins semantics remain compatible.

## risks and decisions

- Last-write-wins is retained. Queued reconciliation prevents client-side lost notifications but cannot undo a save that already overwrote a concurrent server edit. Collaborative merging and conditional writes remain out of scope.
- Server and local events are separated internally to prevent backup writes from triggering false remote updates. The external server protocol remains unchanged.
- Request identities and connection identities solve different races. Scoped disconnect alone is insufficient when an old setup completes late; ordered transitions and synchronous abort guards are also required.
- Retry backoff resets only after a healthy interval to avoid rapid reconnect loops against endpoints that accept and immediately close. A healthy long-lived stream must not receive a total HTTP timeout.
- A connection that remains half-open without reporting a transport error may not recover promptly. Test reported failures and real network restoration; an SSE heartbeat watchdog is deferred unless verification proves it necessary for the requested recovery behavior.
- Selection uses logical offset preservation, not semantic diff-based cursor mapping. Initial adoption must not overwrite text entered before loading completes.
- Reconnect read failures preserve existing pane error behavior. No new global connection UI, periodic polling fallback, server event replay, or versioned persistence is introduced.
- `app/` and `server/` are submodules. This planning commit contains only this task document in the parent repository; later app implementation needs its own commit before updating the parent pointer.
