# goal

## command

Fix live updates in ntr when multiple clients are connected to the same server.

Clients must receive changes to both `Note.md` and `todo.txt` without restarting or reopening settings, including when both resources change close together.

Requirements:
- Fix note live-update handling in `app/src/components/NotePane.tsx`: apply incoming changes when the editor is clean, even while focused, preserving the caret where possible. Never silently discard unsaved edits; retain conflict handling.
- Do not permanently lose note updates received during an in-flight save. Reconcile deferred updates after the save completes.
- Fix the SSE bridge in `app/src-tauri/src/http.rs`: automatically reconnect after connection failures, stream errors, or stream closure, using bounded retry backoff. Reject unsuccessful HTTP responses and ensure disconnect/reconfiguration cancels the stream and any pending retries.
- Register the frontend event listener before starting the SSE bridge, and prevent stale subscription cleanup from disconnecting a newer connection.
- Refresh both resources after reconnecting so changes missed while disconnected are recovered even if no new change event arrives.
- Add regression tests for focused clean-note updates, unsaved-note conflicts, updates during saving, dropped connections and recovery, subscription cleanup, and closely spaced task/note changes.
- Verify with two clients: edits from either client propagate to the other; both resources recover after a network interruption or server restart.

Keep the current API and last-write-wins storage semantics. Collaborative text merging is outside this task. Record test results and any manual verification that could not be performed.

## goal

Restore reliable live synchronization between ntr clients using the same server. A successful task or note mutation should refresh the corresponding resource on other connected clients without requiring a restart, settings change, or note focus cycle. Clients should recover automatically from interrupted connections and fetch current task and note state after reconnecting, including changes made while offline.

Preserve local editing safety. A clean focused note should adopt remote changes while retaining focus and a sensible caret or selection. Incoming changes that differ from unsaved local edits should use the existing conflict flow, not silently overwrite local text. Changes arriving during a save should be reconciled after that save finishes rather than discarded. Empty remote notes must also remain valid updates and conflict candidates.

Keep the server HTTP endpoints, `tasks` and `note` change payloads, and plain-file last-write-wins persistence contract. Any client-internal connection identity or recovery notification must not require a server API change. Local-only mode, certificate settings, and local backups should retain their existing behavior. Collaborative merging, server-side version checks, and unrelated cleanup are outside scope.

## current findings

- `app/src/components/NotePane.tsx` skips live reloads for a clean focused editor. Its reconciliation also returns during saving without retaining a pending update; blur currently saves but does not reconcile.
- `app/src-tauri/src/http.rs` runs a single SSE request and exits silently on connection failure, stream error, or closure. It neither validates the response status before reading events nor retries or announces recovery.
- `app/src/api.ts` starts `server_connect` before registering the Tauri listener. Cleanup invokes an unscoped `server_disconnect`, which can abort a newer subscription.
- `app/src-tauri/src/state.rs` holds one SSE task handle without a connection identity. `app/src/App.tsx` routes resource events to the panes but has no reconnect refresh path.
- `server/src/api.rs` broadcasts task and note mutations to SSE subscribers independently. Both client and server file watchers poll both resources; no evidence currently requires changing the server protocol to support closely spaced changes.
- The existing `app/src/components/NotePane.test.tsx` and `app/src/api.test.ts` tests passed during diagnosis: 59 tests total. This is a baseline, not evidence that reconnect or focused-note update behavior works.

## acceptance criteria

- With two clients connected to the same server, task and note edits from either client appear on the other without reopening settings, restarting, or changing note focus. Closely spaced task and note changes refresh both resources.
- A remote update reaches a clean focused note without losing focus or unnecessarily resetting its caret or selection. Unsaved local edits remain intact until an explicit conflict choice when remote text differs, including when remote text is empty.
- Note updates observed during an in-flight save are not permanently skipped. Reconciliation runs after saving finishes and does not discard newer local input or bypass conflict handling.
- Failed SSE connection attempts, unsuccessful HTTP responses, stream errors, and stream closure trigger automatic retries with bounded backoff. Retry delays and active streams stop when disconnected or replaced.
- Subscription setup observes connection and change notifications from the start. Late setup completion, old cleanup, or delayed events from a superseded connection cannot disconnect or refresh the current connection incorrectly.
- Each successful initial connection or reconnection refreshes both resources through the normal read paths, recovering changes missed offline even when no further mutation occurs.
- Automated regressions cover focused-note adoption and caret behavior, dirty-note conflicts, updates during saving, failed and dropped connections, retry cancellation, listener ordering, stale cleanup, reconnect refresh, and closely spaced task/note events.
- Verification includes relevant frontend and native tests and a two-client check with a network interruption or server restart. Record exact results and explicitly identify any manual or native verification unavailable in the environment.

This stage records a fresh goal only. Implementation belongs to later workflow stages.
