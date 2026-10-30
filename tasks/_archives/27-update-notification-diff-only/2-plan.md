# Diff-only update notification plan

- [Diff-only update notification plan](#diff-only-update-notification-plan)
  - [Scope](#scope)
  - [Implementation Plan](#implementation-plan)
    - [1. Remove notification prose](#1-remove-notification-prose)
    - [2. Keep only diff content and compact inspection controls](#2-keep-only-diff-content-and-compact-inspection-controls)
    - [3. Preserve meaningful diff evidence](#3-preserve-meaningful-diff-evidence)
    - [4. Verify and document](#4-verify-and-document)
  - [Acceptance Criteria](#acceptance-criteria)
  - [Risks And Decisions](#risks-and-decisions)

## Scope

Make remote-update notifications display the diff without surrounding messages. Remove visible notification headings, reassurance/explanation paragraphs, summaries, legends, verbose pagination sentences, and empty-state prose. Keep only the diff and the controls needed to inspect, approve, dismiss, or retry an update. Preserve accessible naming, accurate evidence, bounded inspection, and existing approval/draft safety. Do not redesign rename dialogs, change coordinator semantics, modify native/server protocols, add dependencies, or touch unrelated user work. Planning changes only `2-plan.md`; code, docs, version updates, and implementation results belong to the later implementation workflow.

## Implementation Plan

### 1. Remove notification prose

- In `app/src/components/RemoteUpdateDialog.tsx`, remove the visible “Tasks/Note changed elsewhere. Update now?” heading and “Nothing changes until you approve” paragraph. Replace the removed heading's `aria-labelledby` reference with a concise resource-specific `aria-label`, such as `Task update` or `Note update`, so the native dialog remains named without a visible title or broken reference.
- Preserve the native dialog ID, selector-style surface, preview placement, owned cancel/close handlers, once-only dismissal, and exact-offer approval callbacks. Keep Update and Not now actions, disabled busy controls, and the existing Checking… action state. Do not change offer selection or App's modal queue.
- Remove the visible error paragraph as part of the no-other-messages request, but do not silently conceal failed preparation. When a retryable error exists and the dialog is not busy, label the approval action `Retry update`; retain its current revalidation behavior and the same pending offer. Supply the exact error as a visually hidden accessible alert/description associated with that action. Reset its label/description through existing error/offer state, not a new retry coordinator. Do not discard error evidence, auto-approve, or close the dialog on failure.

### 2. Keep only diff content and compact inspection controls

- In `app/src/components/RemoteDiffPreview.tsx`, remove the saved-versus-incoming explanation, `document.summary` paragraph, and marker legend. Retain escaped diff text and its −/+/= markers, text selection, keyboard scrolling, and non-color accessible change labels. Keep the preview region and content area accessibly named without adding visible explanatory text.
- Retain Diff, Accepted, and Incoming as functional inspection controls rather than adding replacement headings. Preserve their pressed state and the existing evidence-bound reset behavior. The default view remains Diff; inspecting full snapshots must not grant approval or compare against unsaved text.
- Replace the page/remaining-character/long-line/end-of-preview sentence with compact Previous/Next controls and a numeric page indicator. Show navigation only when a next page exists or the user is beyond page one; hide it for a complete single page. Give the numeric indicator an accessible page label, and keep continuation/end and character counts available through visually hidden descriptions rather than visible prose. An enabled Next control must make incomplete content evident without suggesting the current page is the whole change.
- Remove the visible “No task content changes” and “Empty content” paragraphs. Use a compact diff empty-set marker such as `∅` inside the content area with an accessible empty-content label. Keep Update/Not now available for legitimate empty-resource offers and metadata-only changes; do not turn a blank preview into implicit approval or convergence.
- Preserve the existing row/character/work budgets and replace-in-place paging for every view. No Show all, cumulative DOM expansion, unbounded comparison, new data fetch, or new preview dependency is needed. In `app/src/style.css`, adjust only remote-specific spacing left by deleted prose; retain viewport constraints, sticky approval controls, and visible focus styling without changing rename/selector presentation.

### 3. Preserve meaningful diff evidence

- In `app/src/lib/remoteDiff.ts`, remove summary-only formatting and counts when no longer consumed. Replace presentation prose with small structured metadata only where it is still needed for truthful rendering or accessibility; do not keep an unused parallel summary pipeline.
- The current note summary is the only explicit trailing-newline disclosure. Preserve that distinction inside the diff using concise EOF annotations associated with the accepted/incoming side, rather than silently deleting it with the summary. Show EOF annotations when the distinction matters; keep them escaped and within the same paging budget as other diff content. Use standard diff-style metadata rather than a replacement explanatory paragraph.
- Shorten the collapsed-context text from “unchanged lines omitted; inspect Accepted/Incoming for all content” to a compact diff hunk/ellipsis marker with the omitted line count. Keep full accepted/incoming inspection available, and expose the marker's meaning accessibly. Large-change fallback remains truthful removed/added accepted/incoming blocks; any fallback explanation belongs in an accessible description, not visible prose above the diff.
- Keep task IDs, raw text, completion state, and creation/completion dates as diff evidence. Removing a task-count summary must not remove identity/lifecycle-only changes or make two different task versions appear identical. Preserve stable-ID matching, removed/added ID replacements, reorder-only equality, exact offer/baseline pairing, and escaped markup. Do not refactor `remoteUpdates.ts` or token validation for this presentation-only task.

### 4. Verify and document

- Update `components/RemoteUpdateDialog.test.tsx` to assert a named dialog with no visible notification heading, explanation, summary, legend, verbose page sentence, or empty-state paragraph. Scope absence assertions to UI-owned elements so user note/task content containing the same words is not incorrectly forbidden. Test both resources, empty notes/tasks, metadata-only tasks, single-page navigation hiding, compact multi-page navigation, and retained action controls.
- Replace old tests expecting `Page N; …` with page-indicator/control-state assertions. Continue testing repeated forward/backward inspection, all three views, giant single lines, bounded DOM/content counts, evidence/view resets, escaped markup, busy cancellation refusal, and once-only dismissal. Add error-path assertions for the visible Retry update action, its accessible error detail, retained diff, and explicit retry against the same offer.
- Update `lib/remoteDiff.test.ts` for removal of summary prose, meaningful EOF/hunk annotations, and metadata-only task evidence. Keep deterministic comparison-budget tests and complete page reconstruction assertions; include any new metadata in render budgets rather than bypassing limits.
- In `remoteApproval.test.tsx` and any relevant existing pane/selector regressions, replace assumptions about the old visible title/error action label with resource-specific accessible dialog names and Update/Retry update controls. Verify preparation/read failures leave panes and drafts unchanged, newer offers still need another explicit choice, deferred notes remain paused, and task/note queues retain separate baselines. Do not rewrite unrelated rename tests or weaken stale-token assertions to accommodate a cosmetic change.
- Run `npm test` and `npm run build` in `app/`, plus `git diff --check` on changed paths. Follow the existing implementation verification convention for native tests/Clippy; record actual commands, failures/retries, and any ignored opt-in test accurately. Manual desktop/mobile checks should confirm the clean diff-only appearance, accessible naming, focus, paging, and approval-control visibility; record headless limitations instead of claiming device acceptance.
- During implementation, update the root/app README summaries and the relevant `app/docs/live-sync.md` notification/inspection descriptions so they no longer promise the removed headings, legends, or verbose page labels. Keep historical task reports unchanged. Bump the app patch version across the existing npm/Cargo/Tauri version entries, write `4-implemented.md`, and commit through the implementation workflow. Leave `todo.md` and unrelated server work untouched.

## Acceptance Criteria

- A normal remote-update notification contains only escaped diff content, compact diff metadata, and functional inspection/approval controls. No visible notification title, reassurance, summary, legend, empty-state sentence, or verbose paging message remains.
- Task and note dialogs remain accessibly named. Error details remain available to assistive technology, and a visible Retry update control distinguishes failure from idle approval without adding an error paragraph.
- Empty content, omitted context, continued pages, EOF differences, and task identity/lifecycle changes remain distinguishable through compact diff notation, controls, and accessible labels. User content is never filtered merely because it resembles removed UI prose.
- All inspection paths retain their current bounded rendering/comparison behavior. Paging and view changes never apply content; Update/Retry update revalidates the precise offer, and Not now/Escape/backdrop preserve deferred content and drafts.
- Relevant tests and the production build pass; implementation verification limits, documentation, version entries, and results are recorded accurately.

## Risks And Decisions

- “Diff only” removes visible informational prose, not action buttons or accessible labels. Diff metadata such as task identity, EOF annotations, and omission markers is part of the diff, not a replacement notification message.
- Error presentation must satisfy both the no-other-messages request and safe recovery: a concise Retry update action is visible, while the exact diagnostic remains accessibly associated and stored in existing error state. This does not authorize hiding errors elsewhere in the application.
- Deleting `document.summary` naively would hide trailing-newline distinctions; preserve the underlying evidence before removing summary-only code. Likewise, a short page indicator must not disguise continued content as a complete diff.
- Visually hidden accessibility descriptions are allowed; `display: none` or broken `aria-labelledby` references are not substitutes. Do not add a new modal framework or change coordinator behavior to accomplish a presentation cleanup.
