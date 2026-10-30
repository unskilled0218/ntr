# Modal design and update diff plan

- [Modal design and update diff plan](#modal-design-and-update-diff-plan)
  - [Scope](#scope)
  - [Implementation Plan](#implementation-plan)
    - [1. Align dialog presentation](#1-align-dialog-presentation)
    - [2. Preserve the create-task selector beneath rename](#2-preserve-the-create-task-selector-beneath-rename)
    - [3. Simplify rename and dismiss successful attempts](#3-simplify-rename-and-dismiss-successful-attempts)
    - [4. Bind remote previews to approval evidence](#4-bind-remote-previews-to-approval-evidence)
    - [5. Render readable task and note diffs](#5-render-readable-task-and-note-diffs)
    - [6. Verify and document](#6-verify-and-document)
  - [Acceptance Criteria](#acceptance-criteria)
  - [Risks And Decisions](#risks-and-decisions)

## Scope

Restyle global and draft-local project rename dialogs and the remote-update notification to match existing project selector dialogs. Simplify the normal rename form, dismiss it after successful completion, keep the create-task project selector underneath rename in normal and compact layouts, and preview remote task/note changes before approval. Preserve existing project-operation recovery, transport ownership, draft protections, and explicit remote approval. Do not change server/native protocols, dependencies, task deletion/removal semantics, other picker handoffs, or unrelated settings/conflict dialogs. This task produces an implementation plan only; implementation code and version updates belong to the later implementation workflow.

## Implementation Plan

### 1. Align dialog presentation

- In `app/src/style.css`, extract or extend a small shared dialog surface class from the existing `select-modal`/`options-modal` styles: themed foreground/background, border, radius, padding, heading spacing, backdrop, and action alignment. Apply it to both instances of `RenameProjectDialog.tsx` and `RemoteUpdateDialog.tsx`; avoid styling rename only by its global ID, which currently excludes the draft-local instance.
- Constrain width and height to the viewport, wrap long project names, and scroll long preview content without pushing approval controls off-screen. Preserve existing selector appearance and visible keyboard focus. Use a wider modifier for remote diffs rather than forcing every dialog to the preview width. Check narrow screens, theme contrast, and wrapped recovery actions.
- Keep native `dialog.showModal()` behavior and existing dialog IDs for integration hooks. Use explicit accessible headings, associated input labels, and shared error/action styles rather than a new modal framework.

### 2. Preserve the create-task selector beneath rename

- Extend the presentation contract through `SelectField.tsx`, `LabelSelect.tsx`, `AddForm.tsx`, and `lib/projectActions.ts` with an explicit action disposition/session handle: retain the current selector for a rename overlay, or close it for the existing replacement handoff. Keep the default close-before-action behavior for other callers. The global owner must communicate the actual opened operation, since a clicked removal icon or recovery entry can resolve to a retained rename, and a rename icon can resolve to retained removal.
- For create-task rename, leave the native project picker open and open the sibling rename dialog after it so rename is on top. In compact mode, also leave Task options open: its conditional children own the picker, so closing it would unmount the selector. Keep action dialogs outside the add form's React submit ancestry. Do not close/reopen the picker just to simulate the requested stack.
- Give the originating picker session an owned close-stack and focus-restoration path, usable by global TodoPane dialogs and draft-local AddForm dialogs. On Cancel, Escape, backdrop, successful rename, or explicit stop-retry, dismiss only rename and restore focus inside the still-open picker. Prefer the related row action; after a successful name change, find the new-name row; fall back to picker Cancel when no related row remains. Update choices and selected state from normal controlled props without resetting the draft or rebuilding the modal session.
- Preserve `ownDialogEvent` and `dialogWasDismissed` ownership checks. Ensure a child event cannot close Options or the project picker, one dismissal runs once, and queued native close events cannot dismiss a subsequent presentation. Do not focus the covered page/Options trigger while the picker remains modal.
- On Review update, explicitly close rename, the originating picker, and its enclosing Options dialog before requesting remote review. App currently suppresses remote offers whenever any other dialog is open; hiding rename alone would deadlock this handoff. Do not automatically reopen this stack over approval or automatically retry afterward. Reopen retained progress through selector actions as today.
- Clear stale session handles on unmount, layout/destination changes, and replacement presentations. Never reopen an old selector or focus a detached element. Removal and Add project retain their existing replacement behavior, and filter-origin actions continue to close their picker unless they are explicitly needed for the create-task rename session.

### 3. Simplify rename and dismiss successful attempts

- In `RenameProjectDialog.tsx`, show the exact title `Rename project`, a read-only original name labelled `Original`, one editable `New project name` input, and Cancel/Rename actions. Remove the normal task-count paragraph, redundant completion text, and empty status spacing; remove the now-unused `count` prop/call sites. Keep a short scope cue for draft-only changes so the simplified UI does not hide local versus global write scope.
- Preserve case-sensitive validation, unchanged-name no-op behavior, collision checks, immutable target after partial progress, disabled busy/read-only actions, and concise conditional error/progress information. Recovery states still expose Review update, Retry rename/Finish labels, and explicit Stop retry controls with the warning that partial writes remain. Simplification must not remove safe recovery authority or destination warnings.
- In `TodoPane.tsx`, dismiss the specific rename presentation only after its awaited `ProjectRename.run()` attempt has fully settled, bulk ownership has been released, and the operation reports `completed`. The operation's completion callback fires before its final changed notification, and unchanged-name completion bypasses that callback, so neither callback alone is a sufficient dismissal hook. Check record/presentation identity, mounted state, and transport ownership before closing or clearing state.
- Publish verified draft mappings and filter/label changes before returning focus to the picker; then retire only the completed record. Do not close a failed, paused, partial, or label-pending rename. Preserve its stopped record and guarded drafts after ordinary dismissal. Keep successful removal behavior unchanged.
- Draft-local rename already closes after its synchronous state update; route that path through the retained-selector session instead of focusing the underlying form trigger. Cover unchanged-name success in both local and global forms without issuing writes.

### 4. Bind remote previews to approval evidence

- Extend the coordinator's offer/preview contract in `lib/remoteUpdates.ts` so each displayed preview has an explicit accepted baseline and the exact pending offer snapshot. Capture baseline evidence when creating the offer; never compare against editor text, suspended drafts, another destination, or a fresh GET made by the preview component. Keep resource-specific typing for note strings and task arrays, and treat captured snapshots as immutable evidence.
- When an own write advances accepted state while an offer remains pending, invalidate/rebuild its preview evidence against the new accepted baseline, even if remote identity is unchanged. Preserve a deferred offer's deferred status when only its baseline changes; a genuinely new remote identity retains existing new-offer behavior. If remote and accepted snapshots converge, clear the offer normally. A prepared token or click referencing old preview evidence must not apply after this replacement.
- Keep `prepare()` rereads, epoch/generation/destination validation, pending-offer identity checks, and synchronous `commit()` intact. A changed remote snapshot discovered on Update must display a replacement diff and require a new explicit Update, not silently apply content absent from the preview. Read/preparation errors retain the preview and retry affordance without acknowledging content.
- Wire `App.tsx` and `RemoteUpdateDialog.tsx` to render the exact offered preview and pass that same offer back on approval. Keep task/note queues independent, busy controls disabled, deferred reviews available, and notification ordering unchanged. Update existing offer fixtures and coordinator tests for the new evidence contract.

### 5. Render readable task and note diffs

- Add a small pure diff helper, for example `app/src/lib/remoteDiff.ts`, and a read-only preview component. Use escaped React text, not rendered Markdown or injected HTML, so task/note content cannot create controls or execute markup. Diff rendering must not fetch, save, merge, or mutate coordinator/editor state.
- For notes, compare lines of the accepted saved note and offered note. Show unchanged context plus explicit removed/added markers, with headings identifying accepted and incoming content. Preserve blank lines and disclose trailing-newline differences. Dirty local notes remain separate protected drafts; state briefly that the preview compares saved accepted content, not unsaved edits.
- For tasks, match stable IDs and show added, removed, and changed tasks with old/new raw text; include active/completed tasks and retain visible lifecycle/date/project/context metadata. Report identity changes even when raw text is unchanged, because task approval identity includes IDs and lifecycle/date fields. Show ID replacements as removed/added rather than guessing a rename; task list reordering alone is not a change under current coordinator identity semantics.
- Use deterministic bounded line comparison: trim common prefix/suffix, run line LCS only within a fixed work budget, and fall back to clearly labelled removed/added blocks for larger changes. Bound initially rendered rows/characters, disclose omitted content, and provide a user-triggered expansion or full read-only before/after view. Do not present a truncated summary as a complete diff or make approval depend on an expensive unbounded comparison.
- Keep `Update` and `Not now` semantics unchanged. Make additions/removals understandable through text markers and accessible labels, not color alone; permit text selection and keyboard scrolling. Previewing either resource must leave pane contents and unsaved drafts unchanged until approval.

### 6. Verify and document

- Extend `components/ModalLifecycle.test.tsx`, `components/SelectField.test.tsx`, `components/AddForm.test.tsx`, and `projectSelectorActions.test.tsx` for retained normal/compact stacks, correct topmost rename, child-only cancellation/backdrop/Escape, once-only dismissal, deferred close events, focus return after renamed/missing rows, successful/no-op auto-dismiss, and unchanged description/due fields. Replace old rename tests that expect a completed dialog and a separate Close click; do not weaken removal assertions or blanket-replace all close calls.
- Extend `projectRename.test.tsx` for complete versus partial/labels-pending behavior, retries, stale destination/unmount completion, preserved records/guards, and Review update closing the entire origin stack before approval. Test recovery dispatch where the requested icon resolves to the opposite retained operation, so disposition follows the actual presentation rather than the icon name.
- Add pure diff tests for empty content, repeated/blank lines, trailing newlines, multiline changes, escaped markup, long content and bounded fallback, task additions/removals/raw edits, completion/date-only changes, ID reassignment, and reorder-only equality. Extend `RemoteUpdateDialog.test.tsx`, `lib/remoteUpdates.test.ts`, and `remoteApproval.test.tsx` for exact baseline/offer pairing, newer offers during preview/preparation, accepted-baseline changes from own writes, deferred-state preservation, stale-token refusal, preparation failures, separate queues, and dirty-note/add/edit draft preservation.
- Run `npm test` and `npm run build` in `app/`; run the existing native tests and Clippy according to repository convention, and `git diff --check` for changed paths. Record headless test limits; manual desktop/mobile checks should confirm actual native stacking, topmost Escape/backdrop behavior, focus, scrolling, contrast, and long-content layouts. Do not claim device acceptance from the jsdom dialog shim.
- During implementation, update the root/app README summaries and relevant `app/docs/project-renaming.md` and `app/docs/live-sync.md` sections for automatic dismissal, retained selector stacks, remote diff baseline semantics, and explicit review handoff. Keep historical task reports intact. Bump the app patch version using all existing npm/Cargo/Tauri version locations, write `4-implemented.md`, and commit through the implementation workflow. Leave `todo.md` and unrelated server work untouched.

## Acceptance Criteria

- Global and draft-local rename and remote-update dialogs use the existing selector visual language and remain usable on narrow screens.
- Ordinary rename shows `Rename project`, `Original`, and a labelled new-name input without the current verbose task-count copy. Verified success and unchanged-name success dismiss rename without another Close click; failures remain recoverable.
- Create-task rename stays above the same project selector. Cancel, Escape, backdrop, success, and stop-retry leave that selector open and usable in both layouts; compact Task options remains beneath it. No accidental task submission, draft reset, or parent cancellation occurs.
- A partial rename still retains acknowledged progress, destination ownership, guarded draft references, recovery entries, and explicit retry/abandon controls. Review update releases all blocking origin dialogs, shows approval, and never resumes writes automatically.
- Remote task and note notifications show a meaningful read-only diff of accepted saved state versus the precise incoming offer before approval. Metadata/ID changes and preview truncation are not hidden. Unsaved text is neither used as the baseline nor overwritten by preview rendering.
- Superseded preview evidence cannot authorize unseen content; own writes, remote changes, destination changes, and preparation failures preserve existing approval safeguards and deferred-note autosave protection.
- Focus/event lifecycle regressions, diff edge cases, existing app tests, and the production build pass. Relevant docs and version entries are updated only during implementation.

## Risks And Decisions

- Immediate dismissal means after verified completion, not immediately after issuing asynchronous writes. Busy attempts remain non-dismissible because issued writes cannot be recalled; partial results remain visible or recoverable.
- Native dialog top-layer order, React event ancestry, and compact conditional mounting are separate concerns. Retaining only an open flag is insufficient if Task options unmounts its children. Use a small explicit origin-session contract rather than a broad global modal manager or selector DOM queries from unrelated owners.
- Shared styling must cover both rename IDs and avoid changing every modal or using `select-modal` as a cosmetic class that misidentifies preview dialogs in existing selectors/tests.
- Preview evidence is approval evidence, not a merge proposal. Refresh it when either side changes, preserve deferred choices where appropriate, and keep existing coordinator validation authoritative. Do not relax task identity rules to make a diff look simpler.
- Diffs compare saved accepted snapshots, not unsaved drafts or remembered-label files. Labels have no separate remote offer or SSE token; this task does not add one. Task IDs can be reassigned after raw replacement, so removed/added entries may be noisy but are truthful.
- Large content must not freeze notification rendering; explicit bounded fallbacks are preferred over a new dependency or an unbounded quadratic diff. Manual native stacking checks remain necessary beyond automated jsdom coverage.
