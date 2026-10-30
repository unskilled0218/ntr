# plan

- [Scope](#scope)
- [Implementation plan](#implementation-plan)
  - [1. Define legacy data behavior](#1-define-legacy-data-behavior)
  - [2. Remove client priority features](#2-remove-client-priority-features)
  - [3. Update local and server contracts](#3-update-local-and-server-contracts)
  - [4. Test and document](#4-test-and-document)
- [Acceptance criteria](#acceptance-criteria)
- [Risks and decisions](#risks-and-decisions)

## Scope

Remove priority as a task-management feature across the client, local backend, and server. Do not bulk rewrite existing task files or remove unrelated task features.

## Implementation plan

### 1. Define legacy data behavior

- Preserve existing leading `(A)`–`(Z)` tokens as hidden legacy data and `pri:` tokens as editable text, not as editable or sortable priority. Do not generate new priority tokens or move them during completion and reopening.
- Keep enough internal parsing information to recognize a legacy leading token before dates and round-trip it without losing creation or completion dates. Preserve it across edits and lifecycle changes, including completed legacy lines; treat `pri:` as an ordinary tag and preserve it like other unmanaged tags.
- Do not migrate files on read. Ensure list, edit, complete, reopen, and unrelated writes do not silently discard legacy tokens or unrelated content. Make the preservation behavior consistent in both Rust task models and the client edit serializer.
- The task DTO's existing `raw` line is the authoritative source of the hidden leading legacy token for edits, including responses from older servers. Parse only a complete uppercase `(A)`–`(Z)` token at the beginning of an active line or immediately after `x ` on a completed line, before dates; do not interpret malformed or embedded lookalikes as legacy tokens. Reconstruct it in that same position, followed by the parsed lifecycle dates and edited body, without exposing it in a priority control.
- Keep the DTO's parsed dates and description authoritative for their respective edit fields; do not recover them by heuristically splitting the body. Validate that `raw` agrees with the DTO's completion state and lifecycle dates before preserving and submitting a legacy token. If `raw` is missing, malformed, or inconsistent in a way that prevents safe reconstruction, fail the edit visibly without writing rather than guessing or dropping data. Define and test these checks for both old and new response shapes.
- Treat all `pri:` occurrences as ordinary visible, editable description text, not as hidden tags or a priority control. Initialize the edit field from the full description without stripping these tokens. Serialize exactly the occurrences and relative order the user submits, including repeated identical and distinct values; do not restore originals from the collapsed tags map. An unchanged edit retains them; explicit changes or removal must not resurrect old values. Preserve the existing handling of other managed and unmanaged fields.
- Because the file format cannot distinguish a leading `(A)`–`(Z)` description token from legacy priority, reject an add or edit whose submitted description begins with such a complete token, including `(A)` alone, with a clear inline explanation and no write. Keep the input and other form state intact so the user can revise it. This applies to newly submitted description text, not an existing hidden token recovered from `raw`; allow malformed lookalikes and priority-shaped tokens later in the description as ordinary text. Document the limitation rather than silently altering user input.

### 2. Remove client priority features

- Remove priority controls and state from `app/src/components/AddForm.tsx` and `EditTaskModal.tsx`, priority rendering from `TaskItem.tsx`, and unused priority styles and picker configuration.
- Remove priority handling from `labels.ts` composition and editing, while preserving legacy data as defined above and retaining dates, projects, contexts, due dates, other tags, and updated metadata.
- Remove priority sorting from `config.ts` and the sort picker. Verify an existing `ntr.sort=priority` preference falls back to file order without errors; preserve the existing direction preference behavior.
- Remove priority from frontend task/filter types and both HTTP and Tauri request construction. Keep compatibility with older servers that return extra JSON fields.

### 3. Update local and server contracts

- Update `app/src-tauri/src/task.rs` and `server/src/task.rs` together. Remove active priority semantics and priority conversion on complete/reopen while implementing legacy token preservation and correct date parsing.
- Remove priority filtering from both stores, frontend requests, and task DTOs. Explicitly detect any HTTP `priority` query and return a clear HTTP 400, including empty, invalid, and repeated values; retain supported unrelated filters and their existing validation. Do not rely on unknown-field deserialization to reject it.
- For the Tauri command, retain a compatibility-only optional `priority` argument at the boundary: accept omitted or null values used by older clients, but reject non-null values with a clear error before querying the store. Remove the argument from new frontend calls and document this boundary behavior.
- Support the new client with the new server and local backend for the full preservation guarantee. For a new client connected to an older server, preserve tokens on edits using `raw`, but explicitly exclude completion and reopening from the guarantee: the old server can convert legacy priority to or from `pri:X`. Document that users must upgrade the server before those actions if exact legacy preservation matters; do not claim extra JSON fields alone make lifecycle behavior compatible.
- Account for independent `app` and `server` Git submodules when implementing: commit their changes in their own repositories and update their parent pointers as required by the implementation workflow. Document older clients with a new server as unsupported for priority-dependent behavior, including the explicit filter error.

### 4. Test and document

- Update frontend tests for add/edit in compact and regular layouts, task rows, sorting, persisted settings, API transport, and serializers. Retain coverage of project picker cancellation and unrelated behaviors when removing priority-specific cases.
- Add matching local and server Rust tests for legacy active and completed lines, leading tokens before dates, `pri:` tags, malformed lookalikes, parse/serialize, edits, completion, reopening, and preservation of dates and other metadata. Use equivalent fixtures on both backends and assert persisted and reloaded lines after each operation and after mutating a different task, since writes render the whole store.
- Exercise the real client edit serializer through local and HTTP save/reload paths using old and new DTO shapes. Include missing or inconsistent `raw`, repeated `pri:` tokens, lifecycle dates, and malformed token boundaries. Test HTTP filter rejection for empty, invalid, repeated, and valid priority values alongside unrelated filters; separately test omitted, null, and non-null old Tauri arguments.
- Test add and edit submissions of `(A) call` and `(A)` alone in compact and regular UI: they remain in the form, show the explanation, and cause no write. Verify malformed lookalikes and embedded tokens remain visible and editable after add, edit, complete, and reload in local and new-server modes. Verify an unchanged edit preserves an existing hidden legacy prefix, without treating that prefix as newly submitted text.
- Test `pri:` as editable text with unchanged, added, changed, and deleted tokens, including repeated identical and distinct values in both orders. Assert visible edit text and persisted/reloaded content through local and HTTP paths, including old-server DTOs; verify user deletions are not restored.
- Test a new client against the old-server behavior for edit, completion, and reopening, explicitly asserting the documented conversion limitation rather than claiming the new-server preservation guarantee. Test new-client/new-server and local paths for exact legacy-token preservation.
- Run `npm test` and `npm run build` in `app`, and `cargo test --locked` in `app/src-tauri` and `server`. Record any environment blockers rather than claiming unrun checks passed.
- Update current client feature and server API/todo.txt documentation; leave historical task records untouched.

## Acceptance criteria

- Priority cannot be selected, displayed as a dedicated field, sorted, or filtered in the task manager. New tasks and lifecycle actions do not create priority metadata.
- Ambiguous leading priority-shaped description input is rejected visibly without losing form state; other priority-shaped text and editable `pri:` tokens retain their specified text behavior.
- Existing task data is not bulk modified. Normal operations preserve legacy tokens, lifecycle dates, and unrelated metadata in local mode and with the new server; old-server completion and reopening retain their documented conversion behavior.
- Removed sort preferences fall back safely. Both backends and documented interfaces behave consistently, and relevant tests and builds pass or have documented blockers.

## Risks and decisions

- The goal does not specify whether old priority data should be deleted. This plan chooses non-destructive preservation; confirm before any destructive migration.
- Legacy leading tokens precede dates in todo.txt. Treating them as ordinary leading description without special parsing would lose date interpretation, so preservation requires explicit compatibility handling.
- Removing API fields and filters changes the contract for older clients. Explicitly reject non-null legacy filters and document mixed-version limitations; server upgrade is required for the full lifecycle preservation guarantee.
