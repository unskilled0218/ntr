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
  - Preserve `TaskDto.raw`/description/date consistency required by `app/docs/task-text.md`. Keep ordinary project/context/custom tokens in the HA summary and preserve existing multiline HA descriptions separately. For external HA completions without known lifecycle dates, return null rather than inventing historical dates.

3. Implement the HA adapter in focused new server modules, for example `server/src/homeassistant.rs` and `server/src/task_backend.rs`.
  - Read items using `POST /api/services/todo/get_items?return_response` and parse `service_response[entity_id].items`. Fetch completed and incomplete items; do not treat the entity's incomplete-count state as its task contents.
  - Inspect the selected entity's supported features before enabling operations. Require create/update/delete support and reject unsupported due operations before writing. Recommend HA Local to-do for the intended deployment.
  - Use `todo.add_item`, `todo.update_item`, and `todo.remove_item` for mutations. Address existing items by UID, including completion/reopening, so duplicate summaries remain safe.
  - Because add-item service calls do not guarantee a returned UID, serialize ntr creates and compare before/after UID sets. Resolve only a unique new matching item. On ambiguity or a timeout, report an uncertain outcome, refresh state, and do not retry or guess an identity. A successful HA write followed by a failed read/sidecar save must also be reported as uncertain, not rolled back or replayed.
  - Translate `due:YYYY-MM-DD` into HA `due_date`; preserve HA `due_datetime` as an offset-bearing due token for round trips. Update `app/src/lib` task-text helpers as needed so unchanged dates do not truncate an existing datetime. Define and test explicit due removal against the deployed HA API; if clearing is unsupported, reject before sending other changes.
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
  - Publish existing `tasks` SSE notifications after confirmed mutations and external snapshot changes. Coordinate polling and mutation snapshots to avoid duplicate self-notifications; external changes must not inherit a client's origin filter.
  - On upstream failure, preserve the last comparison snapshot but do not serve stale tasks as healthy authoritative reads. On recovery, compare a fresh snapshot and notify clients. Continue note-file watching independently.

6. Document deployment and compatibility.
  - Add `server/docs/home-assistant.md` covering required inputs, HA Local to-do setup, token-file permissions, CA trust, container secret/read-only CA mounts, one-list scope, sidecar persistence, outage behavior, and no automatic task migration.
  - Update `server/docs/configuration.md`, `server/docs/api.md`, `server/docs/docker-compose.md`, and `server/docs/live-updates.md`. Add a short README link rather than expanding the main README into a guide.
  - Update `app/docs/server-connection.md` and `app/docs/task-text.md` for HA-authoritative reconciliation, due preservation, unsupported bulk actions, and mixed-version limits. Keep Markdown notes documentation unchanged unless a connection example needs clarification.

## Validation

- Add fake-HA adapter and API tests for both completion states, duplicate summaries, stable IDs across restart/reorder/delete/recreate, metadata persistence, external edits, capability failures, filtering, and CRUD.
- Test date-only and offset-bearing datetime round trips, explicit clearing, unrelated edits preserving HA descriptions/due values, invalid summaries, and unsupported entity features.
- Test trusted test-CA success, untrusted CA/wrong-host failures, redirects, authentication failure, malformed responses, unavailable entities, timeout-after-write, ambiguous creates, sidecar write failure, and secret redaction. Use test certificates and tokens, not deployment credentials.
- Test that HA mode never opens/modifies the task file, rejects raw replacement without upstream writes, preserves file mode, and keeps note/label behavior unchanged.
- Add client tests for capability discovery, older-server compatibility, HA reconnect under every conflict strategy, no local upload, safe project actions, unchanged note reconciliation, and HTTP upstream failures not triggering local fallback.
- Test poll recovery, external edits with unchanged item counts, origin filtering, and no repeated notifications for identical snapshots.
- Run `cargo test`, `cargo fmt --check`, and `cargo clippy --all-targets` in `server`; run `npm test`, `npm run build`, `npm run test:task-contract`, and relevant native Rust tests in `app`. No live HA writes or publication during automated checks.
- After configuration is supplied, perform an operator-approved smoke test against a disposable HA list: create duplicate names, edit, set due, complete/reopen, delete, edit from HA, restart ntr, and confirm Markdown notes remain unchanged.

## Acceptance Criteria

- Clients need only the ntr server URL; HA credentials and CA trust stay on the server.
- Tasks use the configured HA list with safe identity, metadata, due preservation, and visible error handling.
- Reconnecting cannot replace HA tasks with local files. Existing task files are preserved without automatic migration.
- HA changes reach clients through the current remote-update approval flow. Notes remain Markdown-backed.
- File-backed deployments and local-only mode retain their existing behavior.
