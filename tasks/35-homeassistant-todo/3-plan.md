# Plan

- [Scope](#scope)
- [Decisions](#decisions)
- [Implementation Plan](#implementation-plan)
- [Validation](#validation)
- [Acceptance Criteria](#acceptance-criteria)

## Scope

Replace file-backed server tasks with a Home Assistant To-do backend when configured. Clients continue connecting only to ntr server. Keep Markdown notes, remembered labels, local-only mode, and existing file-backed server deployments working. No HA settings screen or notes migration is needed.

## Decisions

- Configure one existing `todo.*` entity per ntr server for the first version. HA lists are not ntr projects; retain projects and contexts as task text tokens. Multiple lists and list creation are out of scope.
- Require an operator-supplied HA HTTPS URL, long-lived access token, and entity ID. Accept a PEM CA certificate path, including `homeassistant.lanCA.crt`. These deployment values are not yet supplied; document them as required inputs rather than inventing values.
- Use HA as the authority for task summaries, completion state, and due values. Preserve HA item descriptions without turning them into Markdown notes or overwriting them during ordinary task edits.
- Preserve existing task files untouched. Do not import, merge, or delete their tasks automatically. Explicit migration tooling is out of scope.
- Preserve HA due datetimes, including their offsets, during unrelated edits. Keep the current date-only task UI; adding a datetime picker is out of scope.
- Keep an existing datetime's time and fixed offset when its date changes. Show the retained time/offset beside the date control and provide an explicit clear action. A new date on an undated task remains date-only.
- Keep local-only and server-unavailable fallback behavior. An HA upstream outage returns an HTTP error from ntr, not a connection failure that silently changes the client's task destination.

## Implementation Plan

1. Add server configuration in `server/src/config.rs` and startup wiring in `server/src/main.rs`.
  - Add explicit backend selection, defaulting to the existing file backend, plus `HA_URL`, `HA_TOKEN_FILE`, `HA_TODO_ENTITY`, `HA_CA_FILE`, and a bounded polling interval. Read the token from a server-only secret file.
  - Validate all HA configuration before enabling task writes. Reject incomplete settings, non-HTTPS URLs, URL credentials, invalid entity IDs, and unreadable or invalid CA/token files. Do not log secret-bearing configuration or derive an unredacted debug representation.
  - Build a reusable asynchronous HTTP client with normal hostname and certificate verification, optional additional CA trust, timeouts, and redirects disabled. Never forward the HA token to clients or another origin. Add the needed HTTP/TLS dependency in `server/Cargo.toml`.
  - In HA mode, do not open or watch the task file. Continue loading and watching notes and labels as before. Keep the ntr listener protected by loopback or an authenticating reverse proxy; storing HA credentials on the server does not authenticate ntr clients.

2. Introduce a narrow task-backend boundary around `server/src/store.rs`, `server/src/api.rs`, and `server/src/watch.rs`.
  - Implement list/get/create/update/delete/complete/reopen operations for file and HA backends without holding synchronous locks across network awaits.
  - Keep the existing numeric task DTO and filters. Persist a mapping from `(HA instance, entity ID, item UID)` to monotonically allocated IDs within JavaScript's safe integer range. Never derive identity from summary text, list position, or item counts, and never reuse deleted IDs.
  - Persist ntr-only metadata such as creation/completion dates and hidden legacy tokens in a separate atomic sidecar keyed by HA identity. HA owns core fields; the sidecar must not become an alternative task store. Detect malformed sidecars and fail safely rather than silently reassigning IDs.
  - Preserve `TaskDto.raw`/description/date consistency required by `app/docs/task-text.md`. Keep ordinary project/context/custom tokens in the HA summary and preserve existing multiline HA descriptions separately.
  - Define lifecycle projection explicitly: an incomplete task exposes its known creation date and null completion date. A task completed through a confirmed ntr mutation exposes its known completion date and creation date. For a completed task without a known completion date, expose both lifecycle dates as null and omit both from `raw`, retaining creation privately in the sidecar. Restore known creation on reopen. Editing a completed task in this unknown-date state must not erase the private creation date or invent a completion date from the edit day.
  - Invalidate completion metadata on an observed external reopen or external completion transition. After restart or a polling outage, conservatively invalidate completion-date claims for completed items whose lifecycle continuity cannot be established; preserve private creation metadata. A later confirmed ntr completion establishes a new known completion date. Document that snapshots cannot reveal an external reopen/recomplete cycle occurring entirely between reads; do not claim full HA lifecycle history.

3. Implement the HA adapter in focused new server modules, for example `server/src/homeassistant.rs` and `server/src/task_backend.rs`.
  - Read items using `POST /api/services/todo/get_items?return_response` and parse `service_response[entity_id].items`. Fetch completed and incomplete items; do not treat the entity's incomplete-count state as its task contents.
  - Inspect the selected entity's supported features before enabling operations. Require create/update/delete support and reject unsupported due operations before writing. Recommend HA Local to-do for the intended deployment.
  - Use `todo.add_item`, `todo.update_item`, and `todo.remove_item` for mutations. Address existing items by UID, including completion/reopening, so duplicate summaries remain safe.
  - Because add-item service calls do not guarantee a returned UID, serialize ntr creates and compare before/after UID sets. Resolve only a unique new matching item. On ambiguity or a timeout, report an uncertain outcome, refresh state, and do not retry or guess an identity. A successful HA write followed by a failed read/sidecar save must also be reported as uncertain, not rolled back or replayed.
  - Translate `due:YYYY-MM-DD` into HA `due_date`; preserve HA `due_datetime` as a validated offset-bearing ISO token for round trips. Define and test explicit due removal against the deployed HA API; if clearing is unsupported, reject before sending other changes.
  - Update `app/src/components/EditTaskModal.tsx`, `app/src/labels.ts`, and date display helpers in `app/src/lib/taskDates.ts`/`app/src/components/TaskItem.tsx`. Keep the original due token separate from the valid `YYYY-MM-DD` control value and track `untouched`, `changed-date`, and `cleared` intent. Initialize datetime controls from the date in the supplied offset, not a conversion through the device timezone. Untouched or description-only saves retain the exact original token. A changed date replaces only its date portion, retaining time and fixed offset; show that time/offset as read-only text explaining this behavior. Clearing the date or using an explicit `Clear due` action removes the entire due value. Cancel writes nothing; task changes reset both baseline and intent. Keep existing date-only behavior and do not add a time picker.
  - Recognize datetime due values in metadata display without treating `updated:` or lifecycle dates as datetimes. Preserve the full due value for serialization, display its time/offset so it is not hidden, and keep file-mode datetime tokens lossless. Document fixed-offset retention rather than implying timezone/DST-aware rescheduling.
  - Read current HA data before mutation and patch only intended fields, preserving HA descriptions and unrelated due values. Reject unsupported multiline summaries rather than flattening them silently. Document that HA service calls provide no atomic compare-and-swap guarantee against simultaneous external edits.
  - Map missing items to 404, invalid requests to 400, conflicts/uncertain outcomes to an explicit non-success response, upstream failures to 502/503, and upstream timeouts to 504. Redact tokens, request headers, and upstream bodies from client errors and logs.

4. Make raw-task reconciliation safe in HA mode.
  - Add a small non-secret server capability endpoint describing the task backend and whether raw task replacement is supported. File mode retains existing `/api/raw` behavior; HA mode provides a deterministic text export for existing backups but rejects `PUT /api/raw` before any HA mutation.
  - Update `app/src/api.ts` to discover capabilities before reconciliation writes. For HA mode, load authoritative server tasks and optionally back them up locally, but never apply the local conflict strategy or whole-file upload to HA tasks. Leave note reconciliation unchanged.
  - Treat only an explicit missing capability endpoint as an older file-backed server. Do not downgrade on upstream errors, invalid JSON, or malformed capabilities. Scope capability state to the existing transport generation and clear it on destination changes.
  - Audit `app/src/App.tsx`, live-sync hooks, project rename/delete helpers, and all `/api/raw` consumers. Replace bulk task writes with supported per-item operations where possible; otherwise disable the unsupported action with a clear error before any write. Report partial success for multi-item operations; never simulate a transactional whole-list replacement.
  - Keep existing local fallback/draft ownership guarantees. Local fallback edits must never be automatically uploaded on reconnect to HA. Older clients that attempt raw replacement receive a safe error; document that HA mode needs the updated client.

5. Extend live updates without changing their client-facing protocol.
  - Poll full HA item snapshots at a configurable interval, not just entity state/count. Compare UID, summary, status, due, and description so edits with unchanged incomplete counts are detected.
  - Use one asynchronous coordinator to order polling, pre-write reads, mutation readbacks, lifecycle projection, and comparison-baseline advancement. Ordinary task reads must not silently advance that baseline. Serialize ntr mutation sequences through this coordinator; do not hold synchronous locks across awaits or assume this serializes HA's other writers.
  - Before writing, compare the fresh pre-write snapshot with the last published baseline. Publish any difference as an unfiltered `tasks` rescan before advancing the baseline. After writing, compare readback with the expected delta for the confirmed operation: only its target UID and explicitly intended fields may be attributed to the initiating client. Any additional item/field delta, ambiguous create, failed write/readback, or uncertain outcome requires an unfiltered rescan, never a solely origin-filtered notification. Only suppress duplicate self-notifications when attribution is established; an extra rescan is preferable to missing an external change.
  - Commit comparison-baseline advancement together with the notification decision. A failed or uncertain readback leaves the last published baseline intact and marks a rescan pending; emit an unfiltered rescan immediately and again after a successful recovery refresh as needed. Snapshot changes discovered during recovery always bypass origin filtering. Keep the existing SSE payload and client approval protocol.
  - On upstream failure, preserve the last comparison snapshot but do not serve stale tasks as healthy authoritative reads. On recovery, compare a fresh snapshot and notify clients. Continue note-file watching independently.

6. Document deployment and compatibility.
  - Add `server/docs/home-assistant.md` covering required inputs, HA Local to-do setup, token-file permissions, CA trust, container secret/read-only CA mounts, one-list scope, sidecar persistence, outage behavior, and no automatic task migration.
  - Update `server/docs/configuration.md`, `server/docs/api.md`, `server/docs/docker-compose.md`, and `server/docs/live-updates.md`. Add a short README link rather than expanding the main README into a guide.
  - Update `app/docs/server-connection.md` and `app/docs/task-text.md` for HA-authoritative reconciliation, lifecycle-date projection and continuity limits, date-editor intent and fixed-offset retention, unsupported bulk actions, and mixed-version limits. Keep Markdown notes documentation unchanged unless a connection example needs clarification.

## Validation

- Add fake-HA adapter and API tests for both completion states, duplicate summaries, stable IDs across restart/reorder/delete/recreate, metadata persistence, external edits, capability failures, filtering, and CRUD.
- Add an adapter-to-client-serializer contract scenario: create in ntr with a creation date, complete externally in HA, edit in ntr with both projected dates null, reopen and restore creation, restart, and complete externally again. Assert the DTO/raw invariant and private creation retention at every step. Also test confirmed ntr completion, external reopen invalidating its old completion date, and conservative invalidation after restart/outage.
- Test date-only and offset-bearing datetime round trips, explicit clearing, unrelated edits preserving HA descriptions/due values, invalid summaries, and unsupported entity features.
- Add real editor/display component tests for datetime untouched save, description-only save, changed date retaining time/offset, clear through both supported actions, cancel, and switching tasks. Include positive and negative offsets, dates near device-timezone boundaries, return-to-original-date edits, and file-mode date-only/datetime regressions. Assert the visible date and retained-time explanation as well as the serialized token; helper-only tests are insufficient.
- Test trusted test-CA success, untrusted CA/wrong-host failures, redirects, authentication failure, malformed responses, unavailable entities, timeout-after-write, ambiguous creates, sidecar write failure, and secret redaction. Use test certificates and tokens, not deployment credentials.
- Test that HA mode never opens/modifies the task file, rejects raw replacement without upstream writes, preserves file mode, and keeps note/label behavior unchanged.
- Add client tests for capability discovery, older-server compatibility, HA reconnect under every conflict strategy, no local upload, safe project actions, unchanged note reconciliation, and HTTP upstream failures not triggering local fallback.
- Test poll recovery, external edits with unchanged item counts, origin filtering, and no repeated notifications for identical snapshots.
- Use deterministic polling and explicit concurrency barriers, not sleeps. Edit item B externally before the pre-write read and between the pre/post reads of an ntr edit to A. Subscribe the initiating client with its own client ID; assert it receives an unfiltered rescan, its own confirmed A delta is accounted for, and the remote approval flow still offers B's change. Also cover extra changes to A, overlapping poll/mutation attempts, failed readbacks, and recovery without swallowing deltas through premature baseline advancement.
- Run `cargo test`, `cargo fmt --check`, and `cargo clippy --all-targets` in `server`; run `npm test`, `npm run build`, `npm run test:task-contract`, and relevant native Rust tests in `app`. No live HA writes or publication during automated checks.
- After configuration is supplied, perform an operator-approved smoke test against a disposable HA list: create duplicate names, edit, set due, complete/reopen, delete, edit from HA, restart ntr, and confirm Markdown notes remain unchanged.

## Acceptance Criteria

- Clients need only the ntr server URL; HA credentials and CA trust stay on the server.
- Tasks use the configured HA list with safe identity, metadata, due preservation, and visible error handling.
- Externally completed tasks remain editable without invented dates or loss of private creation history. Date-only controls preserve datetime time/offset unless the user explicitly clears due.
- Reconnecting cannot replace HA tasks with local files. Existing task files are preserved without automatic migration.
- HA changes reach clients through the current remote-update approval flow. Notes remain Markdown-backed.
- Concurrent external changes discovered during ntr mutations generate unfiltered rescans for the initiating client as well as other subscribers.
- File-backed deployments and local-only mode retain their existing behavior.
