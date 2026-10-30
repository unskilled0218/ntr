# Project selector actions plan

- [Project selector actions plan](#project-selector-actions-plan)
  - [Scope](#scope)
  - [Implementation Plan](#implementation-plan)
    - [1. Replace project row action text with accessible icons](#1-replace-project-row-action-text-with-accessible-icons)
    - [2. Expose project actions in the create-task selector](#2-expose-project-actions-in-the-create-task-selector)
    - [3. Preserve drafts and modal ownership](#3-preserve-drafts-and-modal-ownership)
    - [4. Move unfinished-rename recovery into project selectors](#4-move-unfinished-rename-recovery-into-project-selectors)
    - [5. Verify and document behavior](#5-verify-and-document-behavior)
  - [Acceptance Criteria](#acceptance-criteria)
  - [Risks And Decisions](#risks-and-decisions)

## Scope

Use icon-only project Rename and Remove actions in the existing Project filter picker and add both actions to the create-task Project selector, in normal and compact layouts. Remove the standalone `Review rename progress` control without discarding unfinished-operation state or safe retry access.

“Delete project” means the existing project-removal operation: remove its project token from associated tasks and its remembered choice, not delete the tasks themselves. Task-row Edit/Delete controls, context controls, sort pickers, and the edit-task selector are outside this UI expansion. Implement in the `app/` submodule using the existing local/server APIs; no new backend protocol or icon dependency is planned. This stage changes only this plan. Do not touch `todo.md`, unrelated server changes, or other existing user work.

## Implementation Plan

### 1. Replace project row action text with accessible icons

- Update `app/src/components/PickerList.tsx` to render a pencil icon for Rename and a trash icon for project removal, using small inline SVGs or one focused shared icon component. Retain `type="button"`, project-specific accessible names such as `Rename work` and `Remove work`, and useful tooltips. Mark SVGs `aria-hidden="true"` and `focusable="false"`; do not use emoji, external icon fonts, or an added package.
- Keep the project name as a separate selectable control. Icon actions must not select the row, activate a surrounding label, submit a form, or mutate content before the relevant confirmation. Preserve existing `renamable`/`removable` capability gating and keep Add project, None, and All projects free of destructive actions.
- Update `app/src/style.css` for consistent icon dimensions, visible focus, sufficient contrast, clear danger styling for removal, comfortable touch targets, and long-name wrapping without horizontal overflow. Apply the same icon treatment wherever these project row actions are enabled; do not change unrelated task buttons.

### 2. Expose project actions in the create-task selector

- Add optional action capabilities/callbacks through `LabelSelect.tsx` and `AddForm.tsx`, using the existing `SelectField.tsx` picker handoff. Supply them only to the create-task Project selector. Keep LabelSelect usable without management actions for its other callers.
- Distinguish persisted/known project rows from staged-only rows. A name in TodoPane's remembered/task-derived project choices is a global project even if AddForm also has a staged copy. A name present only in AddForm's staged state is a draft-local choice. Pass explicit row scope to the owning handler rather than making PickerList infer storage ownership.
- Route known-project actions to TodoPane's existing `openRename`/removal flow. A rename uses the same captured-destination operation, collision checks, per-task validation, label verification, partial-progress retention, and explicit retry as the filter action. Removal retains confirmation, own-response projection, fresh validation, and truthful partial-failure reporting. Do not implement a second network mutation loop in AddForm.
- Handle staged-only actions inside AddForm without native/server writes. Rename validates the target using existing name rules, rejects a distinct visible target collision, and changes only matching staged/selected/inline project references in that draft after confirmation. Removing a staged-only choice confirms its draft-local scope, removes that staged choice, clears a matching selection, and removes only exact matching project tokens from that draft; all other fields/text remain. Do not invoke the global rename helper, which correctly requires a persisted source project.
- Revalidate row scope, destination, and relevant draft state at confirmation. If a staged-only name becomes a known project while its prompt is open, stop and request a new global confirmation; never silently expand a draft-local action into task-store writes. A disappeared or otherwise stale global source must likewise not authorize a different action.

### 3. Preserve drafts and modal ownership

- Close the selector synchronously before opening a rename/removal prompt. In compact create-task mode, also close the enclosing Task options dialog through its existing `OptionsModalHandle` before handing off. Keep action dialogs outside the create-task form's submit ancestry so confirming Rename/Remove cannot accidentally create a task or clear its draft.
- Track the invocation origin rather than always focusing Project filter on close. Return focus to the create-task Project trigger or compact Task options trigger for actions started there, and retain filter-trigger restoration for filter-origin actions. When handing off to remote approval, release native modality before the next dialog opens rather than restoring an inert background control as the recovery mechanism.
- Cancellation, Escape, and backdrop dismissal before submission perform no writes and leave description, due date, selected project, staged choices, and filter unchanged. Retain busy-dismissal, duplicate-submission, queued-close-event, and partial-write rules from the current rename flow.
- Reuse the existing destination-scoped successful rename event to map AddForm selections, staged choices, and exact inline tokens without remounting forms. For successful global removal, add a narrow confirmed project-removal result/event so draft references are retired only after the full intended task and remembered-label work succeeds. Do not represent deletion as a rename to an empty string or clear a draft merely because a void callback returned.
- Refine the removal handler to return explicit completed/partial/failed outcomes, with affected task responses and original destination where needed. On full completion, remove the source from staged suggestions, clear matching selected fields, and remove only exact source project tokens in affected draft text while preserving unrelated text, due dates, and staged projects. Keep a suspended edit draft's underlying task baseline consistent only with a matching verified own response; unrelated changes retain stale-edit protection.
- On failed/partial removal or rename, keep draft content and selection, show the actual result, and retain guards against ambiguously reintroducing a partially retired project. Offer explicit continuation/resolution rather than silently clearing references, claiming rollback, or automatically repeating stale IDs. Keep note content and pending-note autosave restrictions independent of project actions.

### 4. Move unfinished-rename recovery into project selectors

- Remove TodoPane's standalone `Review rename progress` button from the DOM, including after successful renames. Do not merely hide it with CSS, move it into the accessibility-only tree, or discard operation state to make it disappear. Completed results can be released when their dialog closes while retaining any already-issued one-shot draft mapping event.
- Preserve unfinished rename source/target names, destination, task/label progress, uncertainty evidence, and retry authority rules outside dialog open state. Clicking the Rename icon for either related source or target must reopen that exact retained result, not create a new `target → something` operation or fail the original target-availability check against its own progress.
- Annotate a related project row with a concise accessible unfinished-status description so recovery is discoverable without another floating button. If neither source nor target appears in a selector's normal rows, provide a clearly separate recovery action inside that selector, such as `Resume unfinished rename`, with the pencil icon and source/target context. It is not a selectable project option and must not create a synthetic project or change the current filter/selection.
- Route both filter and create-task selector recovery through one TodoPane handler. An unrelated global rename/removal must not overwrite a retained partial result; explain that it must first be finished or explicitly stopped and offer access to that result. Preserve the existing explicit Stop retry; keep partial changes resolution, with no implied rollback or merge.
- Opening a result, clicking its icon, accepting a remote offer, or revisiting a selector is read-only. New writes require an explicit Retry rename/Finish labels confirmation and fresh validation. An in-dialog Review update action still releases ownership before the standard approval flow, and approval never resumes old writes. A different destination may display a read-only retained result but cannot acquire its write authority; require return/revalidation or explicit abandonment.

### 5. Verify and document behavior

- Extend PickerList/SelectField/FilterBar tests to verify pencil/trash rendering, project-specific accessible names, icon-only visible content, capability gating, keyboard activation, and no row selection, label reactivation, or accidental submission. Keep unrelated sort and task-row behavior unchanged.
- Extend AddForm tests for known versus staged-only projects, normal and compact selectors, successful/canceled staged rename/removal, target collisions, unchanged names, and scope changes before confirmation. Assert that draft-local actions issue no native/server mutations and preserve unrelated draft fields.
- Extend `projectRename.test.tsx`, TodoPane tests, and modal-lifecycle tests using real panes and the coordinator for global rename/removal from the create-task selector. Assert persisted task/label results, preserved description/due/staged fields, selected/inline reference migration, no accidental task creation, correct focus restoration, and closure of selector/Task options before the sibling action dialog.
- Replace tests that click the old standalone control with selector-based recovery. Cover successful rename with no remaining progress control; partial task failure; task-complete/label-pending failure with the source absent and target present; uncertain writes; neither related name present; retained result after Close/Escape/backdrop; and an unrelated project action while recovery is pending. Assert `Review rename progress` is absent, yet retry/finish/stop remain reachable without another server event.
- Cover partial-write → selector recovery → in-dialog Review update → approval → explicit retry. Verify no writes on reopening/approval, no stale-ID replay, no cross-destination mapping, and continued paused note autosave. Add removal failure tests proving incomplete operations do not clear draft references or hide errors. Exercise pending-state and collision guards from both selectors rather than relying only on mocked callbacks.
- Run `npm test` and `npm run build` in `app/`; run native/backend checks if implementation reaches those components. Manually inspect desktop/mobile icon clarity, touch targets, tooltips, keyboard navigation, focus return, and recovery discoverability when available. Record headless/manual limits rather than claiming device acceptance.
- Update `app/README.md`, `app/docs/project-renaming.md`, and relevant feature/live-sync documentation for icon actions, create-task selector access, draft-local versus global scope, and selector-based recovery. Replace current UI instructions referencing the removed standalone button; do not rewrite historical task reports. Follow the existing app version convention and record the app commit, parent submodule pointer, and verification results during implementation.

## Acceptance Criteria

- Project Rename and Remove actions use accessible pencil/trash icon buttons in the Project filter and create-task Project selectors, including compact mode. Project names remain separately selectable, with no action controls on sentinel options.
- Known-project actions from either selector share the existing global persistence and approval boundaries. Removing a project never deletes its tasks. Staged-only create-task project actions remain draft-local and cannot silently become global writes.
- Action confirmation cannot create a task, reset unrelated draft fields, stack over an unclosed Task options/selector dialog, or restore focus to the wrong trigger. Cancellation before submission is read-only.
- Full success updates matching draft project references and choices; partial/failed operations retain truthful draft state and actionable restrictions/results. No callback completion alone is treated as proof that every resource succeeded.
- No standalone `Review rename progress` control is displayed or exposed to assistive technology. Unfinished rename recovery remains discoverable and reachable through the related project Rename icons, with an in-selector fallback when neither name is present.
- Reopening recovery or approving remote content never resumes writes. Explicit revalidation and retry are required; another project action cannot erase retained partial progress or transfer authority to a different destination.
- Pending notes, unrelated tasks/projects, active filters, and stale-edit protections retain their intended behavior. Automated checks pass, and unavailable manual/device checks are recorded.

## Risks And Decisions

- A trash icon can imply deleting tasks. Keep the existing project-removal semantics and clear confirmation text; icon-only presentation must retain an accessible action name and scope explanation. This task does not redesign task-row controls.
- The create-task selector combines remembered/task-derived projects with unsaved staged choices. Their storage and lifecycle are different; explicit scope and confirmation-time revalidation prevent accidental global mutation or resurrection through stale staged state.
- Removing a recovery entry without replacement can strand guarded drafts or label-only failures. Recovery moves into selectors; retained state and authority do not disappear with the old button. Use a separate fallback recovery control, not a fake project row, when the source and target are absent.
- Rename and removal dialogs can be launched from inside a form and a compact Options dialog. Preserve event ownership, close-before-open handoff, duplicate-click protection, and origin-aware focus restoration instead of relying on headless clicks into an inert background.
- Existing multi-request partial completion, last-write-wins races, labels-only notification limits, and mounted-pane-only progress retention remain unchanged. Icons and a second entry point do not introduce a transaction, permanent alias, or durable operation journal.
- Keep changes focused on shared project actions, draft outcomes, and recovery routing. Do not replace the coordinator, duplicate its network workflow in AddForm, modify unrelated server work, or reuse an older task's plan.
