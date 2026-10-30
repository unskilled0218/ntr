# Project name editing plan

- [Project name editing plan](#project-name-editing-plan)
  - [Scope](#scope)
  - [Implementation Plan](#implementation-plan)
    - [1. Define rename semantics and pure transformations](#1-define-rename-semantics-and-pure-transformations)
    - [2. Add an accessible project rename flow](#2-add-an-accessible-project-rename-flow)
    - [3. Coordinate destination-scoped task updates](#3-coordinate-destination-scoped-task-updates)
    - [4. Commit remembered projects and track partial completion](#4-commit-remembered-projects-and-track-partial-completion)
    - [5. Preserve filters and unsaved draft references](#5-preserve-filters-and-unsaved-draft-references)
    - [6. Verify behavior and document limits](#6-verify-behavior-and-document-limits)
  - [Acceptance Criteria](#acceptance-criteria)
  - [Risks And Decisions](#risks-and-decisions)

## Scope

Allow renaming an existing project from the task pane's Project filter picker in normal and compact layouts. Rename exact project tokens in every associated active or completed task, update remembered project choices, and move the active filter and relevant draft references to the new name. Preserve unrelated task text, metadata, note content, and unsaved fields.

Implement primarily in the `app/` Git submodule using existing task and label APIs in local and server modes. No new server endpoint, persistent alias system, context-renaming feature, or automatic merge of two projects is planned. Record the app implementation commit and update the parent submodule pointer during implementation. Do not modify implementation code in this planning stage or touch `todo.md`.

## Implementation Plan

### 1. Define rename semantics and pure transformations

- Extend `app/src/labels.ts` with focused project-rename helpers and tests. Reuse `parseLabelInput` for trimming, optional leading sigils, and validation. Names remain case-sensitive, matching task parsing. An unchanged normalized name is a no-op with no writes.
- Reject a distinct target already present in remembered projects, task-derived projects, or locally staged projects; explain that renaming does not merge existing projects. Revalidate the collision check before the first write and before final label persistence. Allow renaming remembered-only projects with no associated tasks.
- Replace only whitespace-delimited tokens exactly equal to `+old`, including repeated occurrences and occurrences among multiple projects. Preserve separators and every unrelated token; leave `+oldish`, ordinary words, URLs, contexts, tags, legacy priority prefixes, completion markers, and dates untouched. Do not use `composeEditedTask`, which adds `updated:` metadata and reconstructs unrelated fields.
- Return a rename plan containing each affected task's ID, expected raw text, and replacement raw text. Keep a separate pure transformation for remembered projects that replaces the source once, preserves unrelated projects and contexts, and avoids duplicates. Treat task and remembered-label completion as separate facts.

### 2. Add an accessible project rename flow

- Add an optional Rename row action through `PickerList.tsx`, `SelectField.tsx`, and `FilterBar.tsx`, exposed only for concrete projects in the filter picker. Keep ordinary selection, Add project, All projects, and Remove behavior intact; do not add rename controls to sort options or context controls.
- Add a focused `RenameProjectDialog.tsx` with the source name, editable target name, validation feedback, affected-task count, and explicit Rename/Cancel actions. Explain that the operation changes associated tasks and matching local draft project references, including inline `+old` tokens; unrelated draft content remains intact.
- Close the picker synchronously through `closePicker()` before opening the rename dialog. Follow `dialogEvents.ts` and `useBackdropClose` for owned Escape, backdrop, and queued-close handling. Cancellation before submission performs no writes and changes no fields or filters.
- Register the rename dialog with TodoPane's existing dialog-ownership callback so remote approval prompts queue behind it. Prevent duplicate submission. During issued writes, show progress and prevent cancellation from implying that completed writes were rolled back. Keep the input and actionable error state after a failure.

### 3. Coordinate destination-scoped task updates

- Add a small project-operation helper under `app/src/lib/` for sequential mutation orchestration, leaving TodoPane responsible for UI state and projections. Capture one `TransportContext`, operation ID, source/target names, and immutable expected-task plan. Stop issuing new writes if the transport generation, destination, mount lifetime, or operation changes.
- Extend `updateTask` in `api.ts` to accept an optional explicit context, defaulting to the current context for existing callers. Validate it before both native and HTTP dispatch, and retain transport-scoped backup checks. Pass the captured context to every task read/write and label read/write belonging to the operation; never recapture a different server halfway through it.
- Before starting a server rename, finish required detection and require the coordinator's accepted task snapshot to match a fresh unfiltered task read, including IDs and raw content. A differing read becomes a normal pending offer without painting it. Require review and a new Rename confirmation rather than replaying the old task plan after acceptance. In local mode, read and validate the current unfiltered task list before constructing the plan.
- For each task, verify the current identity/raw text against the expected own-progress snapshot before writing. Serialize this tab's conflicting task actions while the operation runs. Track and project only successful task responses; never replace the accepted projection with an unrelated full-list read. Use coordinator begin/settle ownership to invalidate older reads and applications without clearing different pending offers.
- Explicitly await and classify post-write detection before the next task rather than treating the operation's own busy rescan as a foreign update. Provide a narrow awaitable coordinator validation result if needed. A verified equal snapshot allows continuation; read failure or genuine divergence stops further writes and retains progress. Do not suppress foreign events or hold one mutation lock across the whole batch, which would hide divergence until every write had completed.
- Use the same focused sequencing boundary for existing project removal where necessary, fixing the task-23 defect in which a slow own-write rescan aborts the next iteration. Preserve real stale-ID blocking and do not automatically resume either operation after remote approval. Keep local watcher refreshes from racing the operation's own task projection; drain queued local refreshes when the operation settles.

### 4. Commit remembered projects and track partial completion

- Suppress per-task remembered-label write-through for this project's multi-step operation. Otherwise `mutate()` and `loadLabels(true)` can repeatedly merge and reintroduce the source label while only some tasks have been renamed. Keep normal single-task behavior unchanged outside the operation.
- After every intended task response has been acknowledged, validate task convergence before finalizing labels. Fetch current remembered labels using the captured context, preserve unrelated projects and every context, replace the source with the target, and persist once. Never substitute empty labels after a read failure or treat a failed PUT as successful completion.
- After persistence, re-read labels to verify that the source is absent, the target exists, and unrelated values from the operation's final read remain. This verifies observed completion only; it does not provide compare-and-swap protection against later concurrent writers. Refresh suggestions from verified labels plus the accepted task projection, without silently accepting pending remote tasks.
- Track completed task IDs, remaining tasks, and label status explicitly. Report task failure separately from “tasks renamed; remembered projects still pending.” Do not roll back already successful task writes or mark the whole operation complete after only one resource succeeds.
- Retry requires current-destination revalidation and an explicit user action. Recompute remaining exact-source tasks from a safely approved/current snapshot and do not rewrite tasks already renamed. If only labels failed, permit a label-only retry even though no task still contains the source. A changed or uncertain write response requires detection before retry, not a blind replay.
- Rename remembered-only projects through the same validated label path even when the task plan is empty. Preserve an actionable local result for partial failure; destination changes invalidate its write authority rather than transferring it to another destination.

### 5. Preserve filters and unsaved draft references

- Update the active filter from source to target only when the relevant operation state warrants it. On full success, a filter selecting the source must select the target, not fall back to All projects. Leave unrelated filters and sorting unchanged. During partial completion, show truthful progress and keep both remaining source and completed target tasks discoverable.
- Add a destination-scoped, one-shot confirmed rename event or equivalent narrow contract to `AddForm.tsx` and `EditTaskModal.tsx`. Update selected projects, staged project choices, and exact inline `+old` tokens in unsaved descriptions without clearing other text, due dates, validation state, or unrelated staged projects. Do not remount forms or replay mappings across destinations.
- Apply draft mappings only after confirmed successful renaming of their relevant project/task state. For partial failures, preserve drafts and block submission of ambiguous source references until the user explicitly resolves or retries the operation. Do not silently recreate a supposedly retired source through stale add/edit fields.
- Keep an edit draft's underlying task identity synchronized only with its own verified rename response. Rebase metadata without rerunning the modal's task-change initializer and losing edited fields. If the task changed for another reason, retain the draft and use the existing stale-edit protection instead of authorizing its save.
- Do not transform notes or clear note pending/deferred state. A task-only mutation and its successful task convergence must not resolve a pending note update or resume paused note autosave. Preserve remote-update review, retained task drafts, and no-automatic-replay guarantees.

### 6. Verify behavior and document limits

- Add pure tests for validation, same-name no-op, collisions, remembered-only projects, exact-token matching, repeated/multiple project tokens, whitespace preservation, active/completed tasks, dates, `updated:` tags, hidden legacy prefixes, contexts, and unrelated labels.
- Extend picker, filter, dialog, and modal-lifecycle tests for normal/compact layouts, accessible Rename controls, handoff without stacked dialogs, Escape/backdrop cancellation, duplicate submission, progress, and retry errors.
- Add local TodoPane integration tests for renaming across filtered and completed tasks, remembered-only renames, active-filter migration, preserved add/edit fields, staged projects, inline project tokens, and edits whose underlying task was renamed. Assert complete persisted task/label results, not only mock call counts.
- Extend `remoteApproval.test.tsx` with the real coordinator and panes. Cover two or more affected tasks, a deferred own-write detection read, self-event filtering, intervening foreign edits/deletions/ID reassignment, failed or uncertain task writes, label GET/PUT/verification failures, label-only retry, target collisions discovered late, settings/transport changes during each stage, and unmount cleanup. Add the corresponding delayed-rescan regression for existing project removal.
- Include a pending remote note while tasks are renamed; assert that the note remains unchanged and autosave remains paused. Verify that approval during recovery never automatically replays an old rename plan or accepts unrelated tasks through label refresh.
- Exercise latest-label merge behavior with an unrelated project/context added before the final GET. Add a later/concurrent legacy writer case to demonstrate the documented last-write-wins boundary rather than claiming client-side reads make cross-client label updates atomic.
- Run `npm test` and `npm run build` in `app/`, plus `cargo test` and `cargo clippy --all-targets` in `app/src-tauri/` for transport regressions. Run additional native/server checks if implementation changes reach those components. Do not install dependencies without permission; record unavailable checks.
- Manually check keyboard and mobile picker-to-rename handoff, focus restoration, long names, and two clients with tasks changing during a rename where possible. Record headless/manual limits honestly. Update `app/docs/features.md` and `app/docs/live-sync.md` with rename behavior, partial progress, draft handling, and concurrency limits; keep tables of contents current. Record verification and version/pointer changes in the implementation report according to the implementation workflow.

## Acceptance Criteria

- Users can rename a concrete project from the Project filter picker in normal and compact layouts. Invalid names and collisions are rejected; cancellation and unchanged-name submission perform no writes.
- Successful renaming replaces all exact source project tokens in associated active/completed tasks and remembered projects, including remembered-only projects. No unrelated task metadata, project, context, or note is changed.
- The active source filter follows the new name. Add/edit drafts retain unrelated fields while selected, staged, and inline source-project references receive the confirmed mapping or remain visibly blocked during an unresolved partial operation.
- Local and server modes work. A slow post-mutation rescan does not truncate renaming or existing project removal. Actual foreign divergence stops stale writes and requires review plus a new explicit operation choice.
- Every operation stays bound to its original transport and destination. Late responses cannot write to or remap forms on a replacement destination. Pending remote task content is never automatically adopted as part of rename recovery.
- Partial task success and label failure are reported separately. Retries revalidate current state, preserve prior successful work, and support label-only completion without blind task replay or destructive empty-label fallbacks.
- Task rename completion does not clear a pending note offer or resume conflicting note autosave. Tests cover persisted results and the real coordinator boundary, including delayed reads and failure paths.
- Documentation states non-atomic multi-request behavior and existing last-write-wins limitations. Automated checks pass or unavailable checks are recorded without unsupported claims.

## Risks And Decisions

- Existing APIs expose individual task updates and whole-label replacement, not a transaction. This plan intentionally uses visible partial completion rather than promising atomic rollback. Validation narrows stale-write risk but cannot eliminate a foreign write between GET and PUT.
- Other clients, including older versions, may rewrite remembered labels from cached state and later reintroduce the source. A final GET/PUT/GET and disabled local write-through during rename do not solve that cross-client race. Durable global rename invariants would require coordinated server protocol/storage changes and compatible writers, outside this task; do not describe this client-only feature as guaranteeing them.
- No existing server SSE token announces labels alone. A remembered-only rename is persisted, but another connected client may not discover it until its next deliberate label read. Do not invent task changes or resolve another resource's approval state to simulate label notification.
- Name collisions are rejected instead of implicitly merging projects. Existing case-sensitive name semantics remain unchanged. No persistent redirect prevents users from deliberately creating the old name in a later independent action.
- The task-23 bulk-removal defect is directly relevant to the new bulk rename path. Fix only the shared sequencing problem and its regression coverage; do not expand this task into a general cleanup.
- Project names may appear in form selections, staged labels, and free-text task drafts. Updating only the picker options is insufficient and can resurrect the source on the next save. Draft mapping must be explicit, scoped, and separate from task-object initialization.
