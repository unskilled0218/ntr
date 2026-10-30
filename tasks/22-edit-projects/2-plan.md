# plan

- [Scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [Summary](#summary)
  - [1. Define rename behavior](#1-define-rename-behavior)
  - [2. Add the project edit interaction](#2-add-the-project-edit-interaction)
  - [3. Implement matching backend operations](#3-implement-matching-backend-operations)
  - [4. Connect transport, refresh, and draft state](#4-connect-transport-refresh-and-draft-state)
  - [5. Verify, document, and record](#5-verify-document-and-record)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## Scope

Allow users to rename an existing project from the project filter picker. Apply the change to every matching active or completed task and the remembered project list, in local and new-server modes. Preserve unrelated task content and existing add, remove, filter, and sort behavior. Do not add context editing, project descriptions, or priority-related fixes from task 21. Do not modify `todo.md`.

## Implementation Plan

### Summary

Add an Edit action and a project-name dialog, backed by one dedicated rename operation per backend rather than a frontend loop of task replacements. Each task-store rename uses one write-then-swap save. Tasks and remembered labels remain separate files, so expose partial completion instead of claiming an all-or-nothing transaction across both files.

### 1. Define rename behavior

- Treat names as case-sensitive. Normalize the new name with the current `parseLabelInput` rules: trim, accept a leading user-entered `+`/`@` as the existing name dialog does, then reject empty names, internal whitespace, and `+`, `@`, or `:` in the bare name. Validate the normalized bare destination independently at each backend boundary. Carry the selected source name exactly; do not normalize an existing legacy name into a different source.
- Derive existing projects from the union of remembered names and all task projects, not the currently filtered or active-only view. Support remembered-only projects and task-derived names missing from the remembered list.
- An unchanged normalized name is a no-op with no file write. A missing source and absent destination is a visible stale-selection error with no write. After an uncertain response, a readback showing no source references and a present destination is converged state, not proof that a retry is needed.
- Renaming to an existing destination combines project membership. Require explicit merge confirmation before writing, including a server-side collision found after the client opened the dialog. A rename request without merge approval must reject a collision without writing. Keep only one destination entry in the remembered list; retain unrelated remembered projects and contexts.
- Replace only complete whitespace-delimited `+source` tokens in task descriptions. Preserve repeated occurrence count, token order, and whitespace within the description; do not change `+source-longer`, email/URL substrings, `@source`, or custom tag values. Do not rebuild tasks through `composeEditedTask`, which would change edit stamps or invoke the unrelated description guard.
- Preserve task IDs and file order, completion state, leading hidden legacy tokens, lifecycle dates, `due:`, every `pri:` occurrence, `updated:`, contexts, other projects, and custom tags. Renaming a project does not stamp a task edit date. Existing store-level canonical rendering may normalize lifecycle-prefix whitespace as it already does; do not introduce additional unrelated normalization or claim byte-for-byte preservation of the whole original file.

### 2. Add the project edit interaction

- Extend `PickerList.tsx` and `SelectField.tsx` with an optional Edit action and accessible per-row labels such as `Edit work`. Enable it only for concrete project rows in `FilterBar.tsx`; do not add actions to All projects, sort/direction rows, or unrelated pickers.
- Add a dedicated project rename dialog, owned by `TodoPane.tsx`, with the current name prefilled, Save and Cancel actions, inline validation/errors, and an explanation that the change affects every matching task. When the destination exists, show the explicit merge-confirmation step before sending a merge-approved request.
- Follow the existing `closePicker` handoff: prevent label default activation, close the picker natively before opening its replacement, and isolate nested cancel/close events. Preserve the compact Options dialog, filter state, and unfinished task input when rename is cancelled by button, Escape/native cancellation, or backdrop.
- Disable duplicate submissions while saving. Preserve the typed destination on validation, collision, write, or transport errors. Do not interpret a rejected or lost response as proof that nothing changed.

### 3. Implement matching backend operations

- Add equivalent project-token replacement logic to the local and server task models, and bulk-rename methods to both stores. Build the changed entry set in memory, save the task file once, and update cached entries only after that write succeeds. Avoid writes when no task token changes.
- Add remembered-project transformation helpers to both label stores. Remove the source, insert or reuse the destination once, preserve unrelated projects and all contexts, and skip unchanged writes.
- Add `POST /api/projects/rename` in `server/src/api.rs` and a registered Tauri `rename_project` command in `app/src-tauri/src/commands.rs`/`lib.rs`, with the same request fields: `old_name`, `new_name`, and `merge` defaulting to false. Define matching success/error payloads, including changed-task count and whether task and label writes committed. Validation/missing-source/collision errors must be distinct; use HTTP 400/404/409 respectively, with no writes at those boundaries.
- Under appropriate locks, validate the source/destination against the current full task and label stores before writing. Acquire both store locks before mutation and use a consistent order compatible with existing rollback paths. In local mode, serialize this operation with `set_data_dir` so file moves cannot interleave with a two-resource rename; audit its existing label-to-task rollback lock acquisition rather than introducing a task-to-label deadlock.
- Commit the task file first, then remembered labels. If the task write fails, neither labels nor either cached task state should change. If the label write fails after tasks commit, leave the successfully committed task state intact and return an explicit partial-completion error; do not silently report success or blindly roll back already-written task data.
- Make recovery after partial completion deliberate: reload authoritative state, show which resource needs finishing, and allow the user to confirm a retry/merge using the same source/destination. Replacing remaining source tokens and deduplicating the remembered destination must be repeat-safe. A fully completed request whose response was lost should be recognized by readback, not blindly replayed against newly changed task lines.
- On the server, notify `Change::Tasks` for successful changes, including remembered-only renames, and after a task commit followed by a label failure so connected clients can refresh. Preserve the local command convention of caller-driven refresh rather than adding a second local event emitter.

### 4. Connect transport, refresh, and draft state

- Add typed `renameProject` transport support in `app/src/api.ts`. Capture one `TransportContext` for validation reads, mutation, reconciliation, and any backup; never follow a settings change by continuing the operation against another destination. Ignore stale completion for current UI state and prevent a rename spanning a local-directory switch.
- Preserve structured rename errors through the HTTP adapter instead of reducing them to the current generic status-only message. Keep existing endpoint error behavior unchanged. Treat an older server's missing rename endpoint as an explicit unsupported-feature error; do not fall back to a client-side task-update loop.
- On success, refresh all relevant tasks and remembered labels. Map a currently selected source filter to the destination; leave All projects and unrelated filters unchanged. Apply the mapping before generic vanished-filter clearing can erase it, and invalidate pre-rename read generations so late results cannot restore the old selection or list.
- Update any locally pending AddForm project selection and staged project names from source to destination without clearing description or due-date input. Keep hidden extra project references consistent if an open task draft is affected by this client's rename; do not reset the entire draft merely to change its project reference. Do not infer a global rename mapping from an unrelated remote refresh.
- Prevent `loadLabels` or an older in-flight label-merge PUT from restoring the old remembered name after success. Coordinate label reads/writes with the mutation and refresh from the backend's authoritative result rather than writing an earlier cached union.
- On partial or uncertain failure, reconcile tasks and labels from the original destination and keep the error visible after refresh. Offer explicit completion/retry only after examining current state; never clear the name field or say the entire operation failed without accounting for committed tasks. Refresh server-mode local task and label backups from confirmed authoritative data, gated by the original transport generation; backup failures remain separate from the primary rename result.

### 5. Verify, document, and record

- Add pure/model/store tests with equivalent local/server fixtures for exact boundaries, prefix collisions, duplicate occurrences, Unicode project names, invalid destinations, same-name no-ops, active/completed tasks, remembered-only and derived-only names, and confirmed/unconfirmed destination collisions. Assert task IDs/order and all unrelated dates, hidden legacy data, repeated `pri:` text, tags, contexts, and other projects survive persistence and reload.
- Inject failures before the task write and before the label write. Verify on-disk and cached states, structured partial status, notifications, visible errors, explicit retry completion, and lost-response readback. Include concurrent collision detection and local data-directory coordination/lock ordering.
- Exercise actual local command logic and HTTP rename/save/reload paths, not only mocked frontend requests. Test supported new client/new server operation and explicit failure with an older server; no mutation may be sent as a fallback after an unsupported response.
- Extend picker, filter, TodoPane, AddForm, and rename-dialog tests in regular and compact layouts. Cover cancellation and deferred native-close handoff, pending-state double clicks, inline validation, merge confirmation, filter remapping, remembered-only projects, preserving unfinished description/due/project state, and stale reads/label PUTs arriving after rename or a transport switch.
- Run `npm test` and `npm run build` in `app`, and `cargo test --locked` in both `app/src-tauri` and `server`. Run focused transport/integration checks for the new operation. Record environment blockers and distinguish executed tests from unrun native-device checks.
- Update the relevant client/server READMEs and focused project-edit/API documentation, including collision, partial-failure, retry, older-server, and last-write-wins limits. Advance app/server versions and release mirrors using their existing conventions, without publishing a release. Record changes and verification in `4-implemented.md`, commit each changed submodule independently, and update parent pointers during implementation.

## Acceptance Criteria

- Users can edit project names from the project filter in both layouts, cancel without mutation, and see invalid names or merge collisions before unapproved writes.
- A successful rename updates matching active and completed tasks plus remembered projects, retains unrelated data, and survives backend reload. Remembered-only and task-derived-only projects work.
- Existing destinations require explicit merge approval. Same-name saves do not write. Source-name matching is exact and case-sensitive.
- Selected filters and pending local project choices follow a successful rename without losing other form fields. Stale reads or label writes do not resurrect the old name during the operation.
- Each task rename is one backend task-file save. Partial task/label failures and uncertain responses are visible and reconcilable; they are not misrepresented as atomic success or atomic failure.
- Local and new-server behavior agree. Older servers fail clearly without a destructive fallback. Relevant automated checks pass or have recorded blockers.

## Risks And Decisions

- The goal is interpreted as renaming projects globally, not merely choosing a different project on one task. Editing contexts and fixing task-21 review findings remain out of scope.
- Combining existing destinations is supported only with explicit user approval; it does not change unrelated projects or deduplicate task text beyond the required token replacement. The backend must recheck collisions, not trust the picker snapshot.
- `todo.txt` and remembered labels are independent files. This plan guarantees per-file write-then-swap behavior and explicit partial-state recovery, not crash-atomic multi-file transactions. A process crash or network loss between writes requires readback and user-directed reconciliation.
- File-backed task writes still render the full store. Keep the rename within parsed description tokens so lifecycle metadata and ambiguous leading description text are not reinterpreted by the task edit serializer.
- Existing storage is last-write-wins. Locks coordinate this operation with mutations in the same backend process, not external editors, old clients, or stale task drafts on another client. Do not introduce a general distributed transaction, durable rename log, or whole-task conflict-resolution system for this feature; document the remaining concurrency limits.
