# plan

## scope

Implement `1-goal.md` by removing context controls, context presentation, and the status filter from the app's todo interface. Keep active and completed tasks visible, with project filtering and the remaining sort choices available.

Implementation belongs in the `app` submodule. Keep the existing local/server task and labels contracts compatible, including stored contexts and task completion. Record this plan beside the current task's goal, following the shared task-directory convention.

## Implementation Plan

### 1. Remove obsolete view options and migrate saved preferences

- In `app/src/config.ts`, remove `STATUSES`, `Status`, and the `contexts` entry from `SORTS`. Keep file, priority, due, created, and projects sorts, plus ASC/DESC.
- In `app/src/settings.ts`, remove `getStatus` and `setStatus`. Add a small legacy-preference cleanup function that removes `ntr.status`, and call it when the todo pane mounts.
- Keep `getSort` validation against `SORTS`. A stored `ntr.sort=contexts` must return `file` before the first render; preserve the saved direction.
- Retain context support in transport/data types and internal token helpers where needed for compatibility. UI removal does not require deleting generic label serialization utilities.

### 2. Simplify filters and task loading

- In `app/src/components/FilterBar.tsx`, remove status/context props, callbacks, option construction, and controls. Render only Project and Sort in both the inline row and compact Filter options dialog.
- In `app/src/components/TodoPane.tsx`, remove status/context state and persistence wiring. Build the visible-list query with only `project: project || null`, so no completion or context restriction reaches either transport.
- Update refresh dependencies and FilterBar props. Keep completion/reopening handlers, live refresh, edit/delete handling, sorting, and project filter clearing.
- Keep label loading compatible with the existing `{ project, context }` resource. Preserve remembered contexts and existing context merging rather than replacing the context collection with an empty array during project writes.
- Restrict filter-driven removal to projects. Keep the confirmation flow and raw-line project removal, including its preservation of `@context` tokens and completion/date prefixes.

### 3. Remove context inputs and preserve hidden contexts on edit

- In `app/src/components/AddForm.tsx`, remove context selection, staged context state, and context modal callbacks. Keep project creation, priority, due date, and description fields in standard and compact layouts.
- In `app/src/components/EditTaskModal.tsx`, remove the context picker and its state/callbacks. Open label creation only for projects.
- Change `ComposeFields` and `composeText` in `app/src/labels.ts` from one selected `context` to an explicit `contexts: string[]` used for hidden metadata preservation. AddForm supplies `[]`. Add a pure `composeEditedTask` helper that takes the original task's required metadata through a structural type plus edited fields, and supplies all original contexts during every edit save; keep `labels.ts` independent of transport imports.
- Compose each retained context as a separate `@name` token. Preserve existing priority/project/due ordering, and do not reduce multiple stored contexts to the former single picker value.
- Strip parsed context tokens from the editable description using whitespace-delimited whole-token matching. Avoid the existing substring replacement behavior for contexts: removing `@phone` must not damage `@phonebook`, email text, URLs, or embedded `@` characters.
- Reset form/modal state when switching tasks so hidden contexts always come from the current task. Keep LabelModal outside the add form to preserve its existing submit isolation.
- Update user-facing project validation errors in `parseLabelInput` to avoid offering or mentioning context controls. Keep existing accepted/rejected project-name rules.
- Because local `Store::update` replaces the entire raw task line, make `composeEditedTask` the single owner of edit prefixes and hidden metadata. Follow the Rust serialization order: optional `x`, optional active `(priority)`, completion date for completed tasks, creation date, then description and metadata. Emit a completed creation date only when a completion date precedes it; include creation dates on active edits.
- Seed the priority picker with `task.priority`, or a valid `pri:X` value for a completed task when the leading priority is absent. Accept saved A–Z priorities even when the picker only offers A–C replacements. Preserve an unchanged completed priority as one `pri:X` tag, replace that tag when priority changes, and remove it when the user selects None. Normalize completed leading priorities into this same saved tag so reopening restores the displayed value consistently. Do not keep a stale `pri:X` alongside its replacement.
- In `EditTaskModal.submit`, permit an empty edited description when the original task has preserved contexts and `composeEditedTask` produces a nonempty line. This supports context-only stored tasks without inventing description text or exposing contexts. Keep description required for new tasks and other edits.

### 4. Hide context presentation and update documentation

- In `app/src/components/TaskItem.tsx`, remove contexts from `renderMeta`.
- Also remove parsed context tokens from the displayed description through the whole-token helper. Backend `Task.description` includes label tokens, so removing only the metadata row would still display contexts.
- When hiding contexts leaves the visible description empty, show `Task without description` as presentation-only fallback text. Never persist that fallback into the task.
- Preserve task checkboxes, completed styling, dates, project metadata, and Edit/Delete actions. Leave arbitrary email/URL text visible.
- Update comments affected by removed fields and `app/README.md` to describe project filtering and the remaining sort choices accurately.
- Inspect existing layout CSS after the controls shrink; adjust only rules that actually prevent the reduced controls from fitting in standard or compact layouts.

### 5. Update meaningful regression coverage and verify

- Update `app/src/config.test.ts`, `app/src/settings.test.ts`, and `app/src/components/SortField.test.tsx` for the remaining sort choices. Replace status persistence tests with legacy status cleanup and saved-context-sort fallback coverage.
- Update `app/src/components/FilterBar.test.tsx` and `app/src/components/AddForm.test.tsx` for the simplified controls. Verify absence of status/context controls after opening compact Options dialogs, while project creation/filtering and sort direction still work.
- Replace status-selection tests in `app/src/components/TodoPane.test.tsx` with cases seeded with both legacy status values (`active` and `completed`). Use active and completed fixtures, assert both appear, and assert visible-list calls carry no completion/context restriction.
- Verify project selection still affects the list query, completion and reopening trigger the right mutations, and project removal preserves remembered contexts and task context tokens.
- Extend `app/src/components/EditTaskModal.test.tsx` and `app/src/labels.test.ts` for zero/one/multiple contexts, task switching, changed description/project/priority/due fields, and preserved creation/completion dates. Assert submitted text retains all original contexts without accidental duplication. Cover completed effective priority initialization, unchanged priority, replacement, explicit None, and saved priorities above C; verify one correct `pri:X` or no tag as appropriate, including the reopened task's priority during runtime verification.
- Cover a context-only task such as `@phone`: its row has neutral fallback text, editing project/priority/due succeeds with an empty description, and the stored context survives. Assert the fallback never appears in submitted task text, while new tasks still require a description.
- Add focused TaskItem/token-helper coverage for hidden parsed contexts, prefix collisions, and untouched email/URL text. Use realistic descriptions containing the same label tokens as backend DTOs.
- Retain `app/src/api.test.ts` compatibility tests for local/server transport contracts. Add targeted assertions if existing coverage does not prove project-only list requests omit server `completed`/`context` query parameters and send null restrictions locally.
- From `app`, run `npm test` and `npm run build`. These are the repository's test and TypeScript/Vite build commands. Resolve failures caused by this change before recording implementation results.
- Smoke-test standard and compact layouts in local mode and against the optional server: add/edit/delete, project creation/removal/filtering, all remaining sorts and directions, complete/reopen, and relaunch with legacy preferences. Inspect raw task text before and after edits to confirm stored contexts and dates survive. Record any unavailable runtime checks explicitly.

## Acceptance Criteria

- Standard and compact todo layouts expose no context inputs, context creation/removal/filtering controls, context sort, or status picker.
- Neither task metadata nor task description displays parsed context tokens; unrelated `@` text remains intact.
- Context-only tasks have a neutral visible fallback and remain editable without injecting that fallback into stored task text.
- Legacy Active/Completed preferences are removed and cannot hide tasks. Active and completed tasks remain visible under the current project filter.
- Saved Contexts sorting falls back to file order before rendering, without losing the selected direction.
- Project controls, priority, due date, remaining sorts, completion/reopening, edit, and delete continue to work.
- Editing preserves every existing context, task completion state, and existing creation/completion dates in local and server modes.
- A completed task's priority picker shows its effective saved priority. Unchanged, replaced, or cleared priority persists and reopens consistently.
- Project label writes preserve remembered context data, and removing a project does not remove task contexts.
- Updated tests pass with `npm test`; `npm run build` passes. Runtime smoke-test results and any blockers are recorded.

## Risks And Decisions

- "Status" means the All/Active/Completed filter, not task completion. Completion checkboxes and completed styling remain part of the todo interface.
- "Remove context" means removing its structured interface and presentation. The todo.txt format, API fields, remembered labels, and manually entered raw `@context` tokens remain compatible.
- Existing descriptions contain structured tokens. Whole-token matching is required to hide contexts without corrupting human text or similarly named contexts.
- Existing edit serialization retains only the first context and omits dates/completion prefixes. The replacement must preserve hidden contexts and these prefixes because update operations replace whole lines.
- Edit serialization belongs in one pure helper, not modal-specific prefix concatenation. Match existing backend completion/date conventions rather than introducing a new task format.
- Completed priorities use the existing `pri:X` convention and the visible picker is authoritative. Selecting None explicitly clears saved priority; leaving the populated picker unchanged preserves it.
- A valid task can contain contexts without human-readable text. Hiding its contexts must not make its row blank or disable edits to the remaining fields.
- Preserve semantic context values and date/completion metadata, not byte-for-byte whitespace or token position. Do not expand this task into a general rewrite of arbitrary tags or multiple-project editing.
- Keep shared label components and internal context utilities where useful; make their UI callers project-only instead of performing an unrelated component rename or architecture refactor.
- Keep planning files in the parent repository. When implementing, commit app changes in its submodule and record the resulting app pointer and task results in the parent repository.
