# plan

- [Scope](#scope)
- [Implementation plan](#implementation-plan)
  - [1. Separate remote detection from applying content](#1-separate-remote-detection-from-applying-content)
  - [2. Identify self-originated changes](#2-identify-self-originated-changes)
  - [3. Add an explicit update choice](#3-add-an-explicit-update-choice)
  - [4. Preserve note editing and save safety](#4-preserve-note-editing-and-save-safety)
  - [5. Keep task refreshes behind the same approval boundary](#5-keep-task-refreshes-behind-the-same-approval-boundary)
  - [6. Verify and document the new behavior](#6-verify-and-document-the-new-behavior)
- [Acceptance criteria](#acceptance-criteria)
- [Risks and decisions](#risks-and-decisions)

## Scope

Replace automatic adoption of other clients' task and note changes with an in-app notification asking whether to update. Keep SSE as a change detector, including reconnect recovery; removing live sync means removing automatic application, not removing the notification transport. Initial loading, explicit connection changes, local-only file watching, and the existing startup server/local reconciliation remain separate from this remote-update choice.

Do not modify implementation code during this planning stage. Implementation will affect the `app/` and `server/` Git submodules; record their commits and update the parent repository pointers during the implementation workflow. Do not touch `todo.md`.

## Implementation plan

### 1. Separate remote detection from applying content

- Replace the direct server-event-to-pane-refresh routing in `app/src/App.tsx`. Local watcher events should retain their current behavior; server events should request detection only.
- Add a small remote-update coordinator, with tests, under `app/src/lib/`. Track accepted and pending resource snapshots, a dismissed snapshot, request generations, and the active transport. Keep task and note state independent.
- Read changed resources without applying them to panes or writing backups. Compare canonical content with the accepted baseline, including empty notes and task deletions. Use an unfiltered task snapshot, not the current project view, and include task IDs in task identity comparisons because raw-file replacement can reassign them.
- Coalesce repeated signals into one pending update per resource. Repeated events for unchanged or declined content must not reopen the question; a different remote version may prompt again. A resource returning to the accepted content clears its pending update.
- Replace `onConnected: refreshPanes` with detection of both resources after initial baseline establishment. Reconnect must detect missed changes without adopting them. Guard initial-load races so establishing a baseline cannot swallow a change received during loading.
- Preserve transport-generation checks, abort handling, subscription ownership, and bounded retries. Old reads, prompts, and choices must not affect a replacement connection. Failed detection keeps current content and shows a retryable error rather than implying that content is current.

### 2. Identify self-originated changes

- Current server events carry only `tasks` or `note`; there is no author identity. Do not suppress all events during a local save or use a timeout, because this would also hide concurrent changes from other clients.
- Generate one random client-session ID in `app/src/api.ts`, separate from the per-subscription connection ID. Pass it through native HTTP mutations and the SSE handshake using an optional `X-Ntr-Client-Id` header. Extend `ServerRequest`, `server_connect`, and their tests in `app/src-tauri/src/http.rs` accordingly. Do not attach the ID to unrelated external requests or treat it as authentication.
- In `server/src/api.rs`, wrap broadcast changes with optional origin metadata. Successful task, raw-task, and note mutations attach the request's client ID. File-watcher changes have no origin. Preserve the existing `Change` resource enum and adapt internal sender/receiver tests as needed.
- Have `/api/events` omit events whose origin matches that subscriber's supplied client ID. Preserve the existing SSE event name and string payloads for all delivered events, and preserve delivery to clients without an ID. Other clients and out-of-band file changes must still notify normally.
- Successful local writes advance only their own accepted content in the client coordinator. Do not clear a different pending remote update merely because a local write completed.
- Document that precise self-event filtering requires the updated server. With an older server, retain the approval boundary and suppress equal-content echoes by snapshot comparison; do not claim reliable author attribution or discard differing updates as presumed self-events.

### 3. Add an explicit update choice

- Add `app/src/components/RemoteUpdateDialog.tsx` and matching tests/styles. Follow existing native `<dialog>` lifecycle, backdrop, and event-ownership helpers. Identify the changed resource and ask, for example, “Tasks changed elsewhere. Update now?” with `Update` and `Not now` actions.
- Queue task and note questions without stacking modal dialogs. Wait while settings, startup conflicts, or note conflict dialogs own the interaction; retain pending updates until they can be offered safely.
- `Not now`, Escape, and backdrop dismissal must be read-only: retain visible content and drafts, record the declined snapshot, and never write the local version to the server. Do not reuse the note conflict dialog's Keep mine handler for dismissal; it currently performs a PUT.
- `Update` authorizes only the identified resource and offered snapshot. If a refreshed read discovers different content, update the pending question rather than silently applying an unapproved replacement. Keep pending state on a failed read or application and offer retry.
- Expose asynchronous pane/coordinator outcomes so a click does not clear pending state before content is safely applied. Handle duplicate clicks and newer updates arriving while a choice is in progress.

### 4. Preserve note editing and save safety

- Extend `NotePaneHandle` and `app/src/components/NotePane.tsx` to distinguish initial/recovery reads, remote detection, and an explicitly accepted remote snapshot. Share its accepted baseline with the coordinator without exposing editor DOM ownership.
- On remote detection, preserve the current editor text, selection, history, and saved baseline. Suspend pending autosave, blur, pagehide, and follow-up saves while a differing remote note awaits a decision, so opening the prompt cannot overwrite the incoming version.
- Accepting an update for a clean note adopts the offered snapshot through the existing editor-write path and preserves sensible caret offsets. A dirty note still requires the existing explicit unsaved-edit choice before replacement; accepting the notification alone must not discard a draft.
- Declining leaves the note and server untouched. Retain a remote-divergence save guard while that snapshot remains unresolved; a later local save must obtain an explicit keep-local/overwrite choice rather than silently replacing the declined remote version. Escape from the notification must never authorize that overwrite.
- Preserve single-flight save ownership, transport scoping, baseline-return draft protection, empty-text handling, and deferred reconciliation during IME composition or a PUT. An already issued PUT cannot be recalled; after settlement, recheck pending evidence without automatically adopting new remote text.
- Audit internal recovery paths and `ResourceRefresh` callbacks so reconnect, retry, or stale-save recovery cannot bypass the approval gate for a differing remote snapshot. Necessary reads may continue; applying remote content requires the relevant choice.

### 5. Keep task refreshes behind the same approval boundary

- Update `app/src/components/TodoPane.tsx` to retain an accepted unfiltered task snapshot and derive project filtering/sorting locally. A project-filter change must not fetch and display a declined remote version.
- Apply accepted remote snapshots explicitly, including the associated label reads, without clearing add/edit drafts or unexpectedly closing task dialogs. Queue application while a task edit needs protection, or request a separate explicit discard choice.
- Replace unconditional post-mutation full-list refreshes with updates from successful mutation responses or targeted removals against the accepted snapshot. Apply server-returned timestamps and IDs for the user's own actions without importing unrelated remote changes. Refresh remembered labels deliberately rather than using label loading as a hidden full-task refresh.
- Audit error refreshes, project removal, edit completion, and settings callbacks for accidental remote adoption. Explicitly changing the connection may load its initial content; merely closing unchanged settings must not accept a declined update.
- When pending task changes make the visible task IDs unsafe, require an update before edit, complete, delete, or bulk project removal, preserving drafts. Do not send stale-ID mutations or silently update the view as a side effect of clicking an action. Last-write-wins races after a validated action remain an existing storage limitation.

### 6. Verify and document the new behavior

- Add coordinator and dialog tests for accept, decline, Escape, duplicate events, changed pending snapshots, two-resource ordering, read/application failures, transport replacement, and unmount cleanup.
- Update `app/src/App.test.tsx`, `app/src/liveSync.test.tsx`, `app/src/api.test.ts`, and pane tests. Replace automatic-server-adoption expectations with approval tests while retaining local-mode, initial-load, save-ownership, conflict, and IME regressions.
- Cover reconnect without a new mutation, delayed initial reads, unchanged settings, own writes before and after SSE delivery, concurrent foreign writes, declined notes followed by autosave/blur/pagehide, filters after decline, task mutation refreshes, and stale task IDs. Assert both visible content and absence of unintended writes.
- Add server integration tests for origin filtering across two subscribers, legacy subscribers, absent IDs, watcher changes, and every task/raw/note mutation. Extend native tests to verify request and handshake headers while preserving reconnect, cancellation, TLS policy, and listener-order coverage.
- Run `npm test` and `npm run build` in `app/`; run `cargo test` and `cargo clippy --all-targets` in both `app/src-tauri/` and `server/`. Record exact results and unavailable tooling rather than installing packages or claiming unperformed checks.
- Manually verify two clients: one changes tasks and notes, the other stays unchanged until acceptance; declining performs no writes; own changes do not prompt; closely spaced changes and offline edits prompt after reconnect. Verify dirty notes, in-flight saves, mobile dialog dismissal, and declined task edits. Record manual checks that cannot be performed.
- Update `app/docs/live-sync.md` and the relevant feature/server API documentation to describe detection-only SSE, explicit approval, decline behavior, paused conflicting saves, origin-header compatibility, and remaining last-write-wins limitations. Keep Markdown tables of contents current.

## Acceptance criteria

- Another client's task or note change produces an in-app update question without automatically changing displayed content.
- `Update` loads only approved content and preserves existing unsaved-edit protection. Newer content requires a new choice.
- `Not now`, Escape, and backdrop dismissal keep displayed content and drafts unchanged and perform no server writes. Repeated identical notifications do not reopen the question.
- Local changes do not trigger remote-change questions with the updated server, including SSE events arriving before mutation responses. Concurrent foreign changes remain detectable.
- Reconnection detects missed changes but does not apply them. Initial loading and local-only file watching remain functional.
- Filter changes, local mutation refreshes, retries, and unchanged settings cannot silently import declined content. Unsafe stale task actions request an update first.
- Pending remote notes cannot be overwritten by automatic saves while awaiting a safe, explicit decision. Existing draft, IME, empty-note, transport, and single-flight protections remain covered.
- Relevant automated checks pass; implementation records verification limits and documents the changed behavior and server compatibility.

## Risks and decisions

- Use in-app prompts, not operating-system notifications; no new notification permission or platform plugin is needed.
- Declining means “do not load this remote version,” not “push mine.” Existing Keep mine conflict resolution is a separate explicit overwrite action.
- Origin filtering requires an additive server/native change because current resource-only events cannot reliably distinguish authors. Older clients retain their existing wire format and behavior; updated client plus updated server is the supported pairing for precise self-event suppression.
- Content detection reads must remain side-effect-free. Existing backup and startup reconciliation code is not an appropriate remote-detection primitive.
- The server remains last-write-wins; this task does not introduce collaborative merging, persistent revision history, or transactional compare-and-swap writes. A write already in flight may race another client, and a disconnected client cannot detect changes until connectivity returns.
- Startup server/local conflict strategy stays unchanged. Runtime remote-update approval must not inherit automatic server/local reconciliation strategies.
