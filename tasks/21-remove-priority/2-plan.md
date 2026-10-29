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

- Preserve existing leading `(A)`–`(Z)` tokens and `pri:` text as legacy data, not editable or sortable priority. Do not generate new priority tokens or move them during completion and reopening.
- Keep enough internal parsing information to recognize a legacy leading token before dates and round-trip it without losing creation or completion dates. Preserve it across edits and lifecycle changes, including completed legacy lines; treat `pri:` as an ordinary tag and preserve it like other unmanaged tags.
- Do not migrate files on read. Ensure list, edit, complete, reopen, and unrelated writes do not silently discard legacy tokens or unrelated content. Make the preservation behavior consistent in both Rust task models and the client edit serializer.

### 2. Remove client priority features

- Remove priority controls and state from `app/src/components/AddForm.tsx` and `EditTaskModal.tsx`, priority rendering from `TaskItem.tsx`, and unused priority styles and picker configuration.
- Remove priority handling from `labels.ts` composition and editing, while preserving legacy data as defined above and retaining dates, projects, contexts, due dates, other tags, and updated metadata.
- Remove priority sorting from `config.ts` and the sort picker. Verify an existing `ntr.sort=priority` preference falls back to file order without errors; preserve the existing direction preference behavior.
- Remove priority from frontend task/filter types and both HTTP and Tauri request construction. Keep compatibility with older servers that return extra JSON fields.

### 3. Update local and server contracts

- Update `app/src-tauri/src/task.rs` and `server/src/task.rs` together. Remove active priority semantics and priority conversion on complete/reopen while implementing legacy token preservation and correct date parsing.
- Remove priority filtering from both stores, Tauri command arguments and DTO, and server task response/query definitions. Check all callers and update API documentation to reflect the contract. Do not silently turn an explicitly supplied legacy priority filter into an unfiltered result: reject it with a clear error if the existing interfaces permit, and document the chosen compatibility behavior.
- Account for independent `app` and `server` Git submodules when implementing: commit their changes in their own repositories and update their parent pointers as required by the implementation workflow. Check compatibility between a new client and older server, and explicitly document the limitations of older clients with a new server.

### 4. Test and document

- Update frontend tests for add/edit in compact and regular layouts, task rows, sorting, persisted settings, API transport, and serializers. Retain coverage of project picker cancellation and unrelated behaviors when removing priority-specific cases.
- Add matching local and server Rust tests for legacy active and completed lines, leading tokens before dates, `pri:` tags, malformed lookalikes, parse/serialize, edits, completion, reopening, and preservation of dates and other metadata. Exercise both local and HTTP paths, including legacy filter handling and mixed-version response compatibility.
- Run `npm test` and `npm run build` in `app`, and `cargo test --locked` in `app/src-tauri` and `server`. Record any environment blockers rather than claiming unrun checks passed.
- Update current client feature and server API/todo.txt documentation; leave historical task records untouched.

## Acceptance criteria

- Priority cannot be selected, displayed as a dedicated field, sorted, or filtered in the task manager. New tasks and lifecycle actions do not create priority metadata.
- Existing task data is not bulk modified, and normal operations preserve legacy tokens, lifecycle dates, and unrelated metadata in local and server modes.
- Removed sort preferences fall back safely. Both backends and documented interfaces behave consistently, and relevant tests and builds pass or have documented blockers.

## Risks and decisions

- The goal does not specify whether old priority data should be deleted. This plan chooses non-destructive preservation; confirm before any destructive migration.
- Legacy leading tokens precede dates in todo.txt. Treating them as ordinary leading description without special parsing would lose date interpretation, so preservation requires explicit compatibility handling.
- Removing API fields and filters changes the contract for older clients. Do not silently ignore a requested filter; verify the actual framework behavior and document any unavoidable mixed-version limitations.
