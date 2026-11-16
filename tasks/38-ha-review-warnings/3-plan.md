# Plan

- [Scope](#scope)
- [Implementation](#implementation)
- [Verification](#verification)
- [Delivery](#delivery)

## Scope

Fix task 37 review F1 and F2 in the server only. Preserve client APIs, task approval, move confirmation, metadata schema/IDs, no-replay recovery, file-backed stores, and Markdown notes. No UI or workflow redesign is needed; omit `2-design.md`. Leave existing app lockfile edits untouched. No live HA writes, deployment, publication, or push.

## Implementation

1. In the HA coordinator, retain an author origin only if both the task readback matches the expected self-only result and the catalog matches the published pre-write catalog. Otherwise publish an unfiltered task-resource event before consuming either baseline. Keep unchanged self-only writes filtered and unchanged later polls silent.
2. Extend the disposable HA fixture with a one-shot catalog change during a task write. Add real-router SSE regressions for empty-list rename/add/remove and an unchanged-catalog self-only control, covering author delivery and a silent follow-up poll. No sleep-based race orchestration is needed.
3. Add a separate durable whole-file writer for HA sidecars. On supported Unix platforms, write the sibling temporary file, synchronize its contents, rename over the destination, then synchronize the parent directory. Treat a relative filename's empty parent as `.`. Return any write/sync/rename failure; do not continue to dependent HA writes. Reject unsupported platforms rather than claim durability. Leave the existing `atomicfile::write` behavior for file tasks, notes, and labels unchanged.
4. Route every HA sidecar save, including schema migration, move intent, identified target, observation, completion, and recovery, through the durable writer. Introduce only a small private persistence seam for deterministic fault injection, without process-global state or public test-only APIs. Update in-memory metadata only after a successful durable save; retain conservative pending-state blocks after uncertain later stages.
5. Test the operation order and failures before write, file sync, rename, and directory sync. Exercise HA saves at move admission, verified-target persistence, completion, and recovery, including post-rename failures where disk may already contain the new state. Assert no unsafe source deletion, no automatic replay, distinct retained-copy IDs, and restart reconciliation/abandonment behavior.
6. Update the server README, HA durability/platform/filesystem guidance, development testing notes, live-update provenance docs, and release notes. Document that successful fsync relies on truthful local-filesystem/storage semantics, does not make HA transactional, and cannot guarantee against dishonest hardware or unsupported network mounts. Bump server `0.2.12` to `0.2.13` with existing mirrors; do not bump the unchanged app.

## Verification

- Run focused notification/persistence regressions, then server `cargo test --locked`, `cargo fmt --check`, and `cargo clippy --locked --all-targets -- -D warnings`. Use a fresh target directory if cached binaries contain obsolete manifest paths.
- Rerun the real client serializer/HTTPS/WSS contract against the changed server and the existing Compose rendering test. Frontend implementation is unchanged; no native desktop build is required for this server-only correction.
- Validate server version mirrors, report the distinction between deterministic sync-error tests and unperformed physical power-loss tests, and run Git whitespace checks.

## Delivery

After plan review/update, create fresh `38-ha-review-warnings` branches in parent and server. Implement the full plan, record changes and exact verification in `5-implemented.md`, commit the server, then commit the parent report and server pointer. Keep the app branch, pointer, and uncommitted edits unchanged. Notify after each workflow stage.
