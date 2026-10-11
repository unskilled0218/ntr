# plan

## scope

Hide parsed project tokens from the main task-row description while retaining projects in the smaller metadata line. Preserve context hiding, displayed tags, priority/dates, fallback text, and original task objects. Apply the same presentation rule to active/completed tasks through the shared `TaskItem` component.

Change `app/src/components/TaskItem.tsx` and its behavioral tests, plus release metadata during implementation. Reuse existing whole-token helpers; no backend, storage, editing, filtering, sorting, or styling change is needed.

## Implementation Plan

### 1. Reuse exact-token stripping for the row description

- Replace the `hideContexts` import and display call in `TaskItem.tsx` with `bareDescription(task.description, task.projects, task.contexts, {})`.
- Pass an empty tags map deliberately: list rows should hide project/context labels but retain currently displayed tags such as `due:2026-06-30` and `pri:A`. Do not pass `task.tags`, which would hide unrelated content. Add a short comment documenting this list-display distinction from the edit form.
- `bareDescription` already delegates to `stripTokens`, which compares whitespace-delimited tokens against exact parsed label values. Reuse it without changing its implementation or edit-form callers. All occurrences of each parsed project/context token are removed; substring matches and regular-expression stripping are unnecessary.
- Leave `renderMeta` unchanged so every project remains visible beneath the description. Keep existing priority markup, completed styling, and created/completed dates.
- Preserve the existing `|| "Task without description"` fallback after stripping labels. Do not write the cleaned display text into `task.description`, `task.raw`, or any API payload. Action callbacks continue receiving the original `task`.

### 2. Add focused task-row regressions

- Update the existing TaskItem context-hiding test to also require removal of `+work` from `.text`, while `.meta` still contains `+work`. Retain its email/URL and priority assertions.
- Cover multiple and repeated parsed project tokens mixed with contexts. Assert clean main text and the unchanged project metadata list; do not deduplicate or reorder metadata as part of this task.
- Cover complete-token boundaries: embedded `+` text such as `C++`, email/URL content, and a similar token not present in the supplied parsed project list remain visible. Remove only exact tokens represented in `task.projects` and `task.contexts`; the row must not independently reparse descriptions.
- Include a fixture with displayed tags in both `description` and `task.tags`. Assert that project/context tokens disappear while `due:` and other non-label content remain visible, catching accidental use of `bareDescription` with `task.tags`.
- Cover project-only and project-plus-context-only descriptions. Assert the existing fallback and retained project metadata. Keep the existing context-only behavior covered.
- Cover an active row and a completed row, checking unchanged checkbox state, completed class, and applicable dates/priority display. Include a task with no labels to confirm ordinary description content remains visible.
- Verify Edit, Delete, and toggle callbacks receive the same original object, with its stored description/raw/project fields intact. Compare the fixture with a pre-render snapshot after rendering/actions to guard against presentation mutating task data.
- Keep coverage at the rendered behavior boundary. Existing `labels.test.ts` already protects exact-token stripping, so do not add a new helper or duplicate its existing unit cases solely to assert the chosen function call.

### 3. Verify and record the implementation

- From `app`, run `npm test -- src/components/TaskItem.test.tsx src/labels.test.ts src/components/EditTaskModal.test.tsx src/components/TodoPane.test.tsx` to verify display behavior and nearby editing/task-list contracts.
- Run `npm test` and `npm run build` from `app` for the full frontend suite and TypeScript/Vite checks. Run `git diff --check` in the app and parent repositories.
- If a browser/app runtime is available, inspect active/completed rows at mobile and desktop widths using disposable fixtures: project labels should appear only below the main text, and due tags/priority/dates should retain their prior display. Check local/server task views when available. Record unavailable runtime checks rather than claiming jsdom establishes visual layout.
- During implementation, write `4-implemented.md` in this task directory with changed files, exact verification commands/results, and any runtime limits. Frontend tests/build are the required checks for this shared rendering change; native compilation or device packaging is not necessary to verify unchanged Rust code.
- Follow the existing patch-release convention: bump app version from `0.15.11` to `0.15.12` consistently in `app/package.json`, `app/package-lock.json`, `app/src-tauri/Cargo.toml`, `app/src-tauri/Cargo.lock`, and `app/src-tauri/tauri.conf.json`, without dependency upgrades. Confirm the current version if another release intervenes.
- Commit the implementation in the app task branch, then commit the parent submodule pointer and implementation report through the existing workflow.

## Acceptance Criteria

- `call bank +work` renders `call bank` in the main description and `+work` in the metadata line.
- All exact parsed project tokens, including multiple/repeated occurrences, disappear from the main description. Context hiding remains intact, and project metadata remains unchanged.
- Embedded `+`/`@` text, URLs, token-prefix collisions outside the supplied parsed labels, and displayed tags remain intact. Token stripping does not introduce a second parsing policy.
- Label-only descriptions use `Task without description` while retaining project metadata. Unlabelled descriptions remain visible.
- Active/completed rows retain existing priority, dates, checkbox state, styling, and actions. Task descriptions, raw lines, project associations, and callback object identity remain unchanged.
- Focused/full frontend tests, production build, and diff checks pass. Results and any unavailable visual/runtime verification are recorded in `4-implemented.md`.
- Release metadata agrees on the new patch version, and implementation/report commits follow the project workflow.

## Risks And Decisions

- `bareDescription` can remove tags for editing. Passing `{}` in list rendering is an intentional display contract; the rendered tag-retention regression must protect it.
- Parsed projects/contexts are authoritative for hiding labels. Do not use a broad `+word` pattern that can hide ordinary content or remove labels absent from the supplied metadata.
- Existing token stripping normalizes whitespace. Keep that established behavior rather than introducing formatting or punctuation changes.
- The storage and edit model must retain the original description. A cleaned display string is never a replacement task or a save payload.
- Reuse the existing shared row and helper rather than creating separate mobile/server display paths or a new label-hiding abstraction for one caller.
- This stage writes a new plan only; implementation and runtime verification happen in the implementation stage.
