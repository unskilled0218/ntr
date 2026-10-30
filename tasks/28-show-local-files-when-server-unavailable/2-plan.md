# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [Summary](#summary)
  - [1. Distinguish connection failures](#1-distinguish-connection-failures)
  - [2. Own fallback in the transport](#2-own-fallback-in-the-transport)
  - [3. Apply destination changes safely](#3-apply-destination-changes-safely)
  - [4. Show fallback and support reconnect](#4-show-fallback-and-support-reconnect)
  - [5. Add regression coverage and documentation](#5-add-regression-coverage-and-documentation)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Implement task 28 in the `app/` submodule. When a configured server cannot be reached, automatically display the existing local tasks, note, and label suggestions instead of leaving the app showing only `Could not load label suggestions: error sending request for url (server-url)`. Reuse the existing local Tauri commands and local editing behavior. Preserve the configured server URL and provide an explicit reconnect path. No server changes, new synchronization queue, or implementation changes during this planning task.

## Implementation Plan

### Summary

`app/src/api.ts` currently derives every transport context directly from `getServerUrl()`. Its read functions never fall back to local commands. Startup reconciliation catches network errors and returns an empty conflict list, so `App.tsx` mounts panes that still read from the unavailable server. `TodoPane.tsx` reports task and label read failures, while the native SSE bridge retries separately. Fix the shared transport destination rather than hiding errors or independently substituting local results in each pane.

### 1. Distinguish connection failures

- Update `app/src-tauri/src/http.rs` to expose a structured, serializable connection-failure category for resource requests, retaining the original human-readable message. Categorize connection establishment, DNS, TLS, and GET timeout failures without parsing error strings. Keep HTTP responses as responses, including non-2xx statuses; keep malformed URLs, invalid methods, and internal IPC/client errors distinct from server unavailability.
- Normalize these failures at the `serverFetch` boundary in `app/src/api.ts`. Preserve the existing `<status> <statusText>` HTTP error contract and teach `errMsg` to retain native structured messages.
- Trigger automatic fallback only for a current server resource GET with a recognized connection failure. Do not use SSE failure alone as evidence that resource requests cannot work. Do not redirect or replay a failed mutation locally, since its server-side outcome may be unknown.
- Retain the existing 30-second GET deadline. Test timeout classification with short injected deadlines rather than waiting 30 seconds.

### 2. Own fallback in the transport

- Add session-only effective connection state in `app/src/api.ts`, separating the saved configured URL from the active server or local destination. Extend immutable transport context validation to cover both settings identity and effective mode; keep local data-directory generation in local destination identity.
- Add a transport-state subscription for `App.tsx` and a single idempotent transition into local fallback. The first qualifying failure must increment the transport generation synchronously, invalidate the failing server context, and notify subscribers; simultaneous failures must not produce repeated activations.
- Have `captureTransport`, `isTransportCurrent`, `destination`, resource reads, mutations, backup guards, and `onChange` use the same effective destination. Once fallback is active, task IDs and all writes must belong to the local store, not the configured server.
- Do not transparently retry the failing GET with local results under its old server context. Let the old request become obsolete and let the app reload all resources under a fresh local context.
- Ensure startup `reconcileWithServer` stops after invalidation and cannot return stale conflicts or continue copying resources after fallback. Let local initialization finish even if reconciliation failed before panes mounted. A stale failure from an old URL, certificate policy, or data directory must not activate fallback for the new destination.

### 3. Apply destination changes safely

- Refactor the destination-transition handling in `app/src/App.tsx` so settings changes, fallback, and explicit reconnect share one lifecycle. Update `activeContext`, activate `RemoteUpdates`, invalidate conflict offers, rebind subscriptions, and initialize or refresh panes once for the new destination.
- Reuse `NotePane.prepareDestination` and its destination-aware save ownership to retain dirty text without automatically copying a server draft into local storage. Keep the existing explicit version-choice flow when a retained draft differs from the new destination. Do not remount panes to implement fallback, since that would lose drafts and pending save ownership.
- Refresh tasks and remembered labels together under the local context, clear obsolete server read errors, and prevent actions on an old task projection before local tasks are loaded. Audit `TodoPane.tsx` edit ownership, project rename/removal records, queued callbacks, and mutation validation so old server IDs cannot operate on coincidentally matching local IDs. Retain drafts without automatically replaying actions.
- Stop obsolete server subscriptions and resource retries; enable local file watcher refreshes. Cancel old remote approval tokens and ensure local reads are not registered as accepted server snapshots in `app/src/lib/remoteUpdates.ts`.
- Guard late server reads, reconciliation results, backup completions, and pending mutation continuations with their original context. An already-issued server request may settle, but cannot paint over local content, write a backup into the active local store, or release another destination's note-save ownership.

### 4. Show fallback and support reconnect

- Update `app/src/components/SettingsButton.tsx` and connection details in `SettingsModal.tsx` to reflect the effective local mode while preserving the saved server URL in the input. Add a small accessible status such as `Server unavailable; using local files` rather than presenting the raw label error as the only content.
- Make the existing Connect action explicitly retry the configured server even when the URL is unchanged during fallback. Pass that intent to the transport rather than relying only on URL comparison. Closing unchanged settings or changing UI-only preferences must not retry or leave fallback.
- Reconnect is an intentional destination change: invalidate local callbacks, retain drafts, and run the existing startup reconciliation strategy (`ask`, `server`, or `local`) before presenting server content. A repeated connection failure returns to local mode without deleting files or the configured URL. A successful connection restores the server badge and normal remote-update approval behavior.
- Keep fallback active until explicit Connect or app restart. Do not automatically switch an editing session back to the server just because an SSE connection recovers. The existing Use local files action still clears the configured URL and selects deliberate local mode.

### 5. Add regression coverage and documentation

- Extend `app/src/api.test.ts` and native transport tests for typed connection failures, preserved HTTP status errors, current-generation-only fallback, simultaneous failures, effective local routing, and no mutation replay. Cover stale failure after settings changes and late successful responses after fallback.
- Add app-level tests using the real panes and mocked Tauri boundary, following `app/src/liveSync.test.tsx` and `app/src/remoteApproval.test.tsx`. Start with an unreachable configured server and distinct local task, note, and label fixtures; assert all appear, the fallback status is visible, and local reads replace the label-only error state.
- Cover failure during startup reconciliation and after successful startup, including labels-only connection failure. Verify local file events, empty local stores, local read errors, local mutations, unchanged settings, explicit same-URL reconnect, repeated failure, successful reconciliation, and every conflict strategy.
- Extend pane regressions for dirty notes, pending/uncertain saves, IME composition, task edit drafts, project operations, stale task IDs, and pending remote approvals during the switch. Verify no automatic cross-destination write or replay and no silent draft loss.
- Keep existing `503` resource-retry and SSE reconnect tests passing; HTTP errors must not unexpectedly switch stores. Use deferred promises and fake timers for race coverage.
- Update `app/docs/live-sync.md` and connection documentation to explain local fallback, saved URL retention, local editing, explicit reconnect, existing reconciliation choices, and the absence of automatic offline merging. Preserve Markdown tables of contents.
- Run `npm test` and `npm run build` in `app/`; run `cargo test` and `cargo clippy --all-targets` in `app/src-tauri/` where native dependencies are available. Report missing system packages rather than installing them. Manually verify unreachable-server startup, local editing, and explicit reconnect on desktop and Android when available.

## Acceptance Criteria

- With a saved but unreachable server URL, the app displays existing local tasks, note, and remembered labels after connection failure, not only the reported label error.
- Both panes, connection badges, local watcher events, and subsequent writes consistently use the same local destination. Empty local files display normal empty states; genuine local read errors remain visible.
- The server URL and TLS preference remain saved. Certificate validation is never weakened automatically. A clear status identifies local fallback.
- Concurrent or obsolete failures cannot repeatedly transition the app or override a newer destination. Late server responses cannot overwrite local content or clear newer drafts.
- Failed mutations are never replayed against local storage. Server task IDs cannot be used for local mutations, and dirty drafts require the existing explicit cross-destination choice before persistence.
- Connect retries the saved URL during fallback, including an unchanged URL. Success uses existing reconciliation choices and restores server behavior; failure leaves local files accessible. Unchanged settings do not reconnect.
- HTTP response errors, invalid response data, and an SSE-only outage retain existing error/retry behavior rather than silently switching stores.
- Existing approval, note-save ownership, project-operation, local-mode, and connection-recovery regressions pass alongside new fallback tests.

## Risks And Decisions

- Local files are the existing data-directory contents, not a guaranteed fresh or per-server cache. Display them as local files; do not claim they mirror the latest server state or introduce a new backup format.
- Fallback is a whole-app destination change, not a read-through cache. Mixing server tasks with local writes could mutate unrelated task IDs and is explicitly prohibited.
- Preserve normal local editing rather than introducing a new read-only mode. No automatic upload queue or background merge is added. Explicit reconnect may overwrite a side according to the user's existing reconciliation strategy; document this behavior.
- Explicit reconnect avoids unrequested destination changes while editing and keeps recovery scope small. Resource HTTP errors and SSE reconnect behavior otherwise stay unchanged.
- Startup reconciliation currently swallows errors, and settings comparison currently uses URL identity. Both paths must participate in the new state lifecycle; fixing only `getLabels` would leave note loading, writes, and recovery inconsistent.
- Native mutations already accepted by the server cannot be recalled. Preserve single-flight save ownership and do not treat a network error as proof that a mutation failed before reaching storage.
- Respect unrelated working-tree changes, including `todo.md`. This planning commit contains only this task's `2-plan.md`; implementation work will require a separate `app/` submodule commit and parent pointer update.
