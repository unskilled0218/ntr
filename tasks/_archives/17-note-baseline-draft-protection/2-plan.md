# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [1. Capture the baseline-return regression](#1-capture-the-baseline-return-regression)
  - [2. Track editing intent separately from baseline equality](#2-track-editing-intent-separately-from-baseline-equality)
  - [3. Protect reconciliation and resolve provenance explicitly](#3-protect-reconciliation-and-resolve-provenance-explicitly)
  - [4. Verify lifecycle boundaries and existing behavior](#4-verify-lifecycle-boundaries-and-existing-behavior)
  - [5. Document, version, and record results](#5-document-version-and-record-results)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Fix the critical finding in `tasks/16-note-save-ownership/5-code-review.md`: recovery after an invalidated outstanding note save silently adopts older text when newer editing returns the editor to its pre-save baseline. Primary files are `app/src/components/NotePane.tsx` and `app/src/components/NotePane.test.tsx`. Retain destination-scoped single-flight saves, current-context transport checks, existing conflict UI, and ordinary clean-note synchronization. Keep server APIs, storage semantics, SSE recovery, and unrelated code unchanged. The inherited post-recovery-await unmount warning is explicitly outside scope. Do not modify `todo.md`.

## Implementation Plan

### 1. Capture the baseline-return regression

- Add permanent component regressions using the existing deferred transport seam, fake timers, real `activateTransport()`, and real note history/classification. Use modeled storage whose contents change when a controlled PUT commits, not a GET stub that always returns the desired result. Do not depend on the temporary review probes being present.
- Cover both `base` and an empty initial baseline, with both Ctrl+Z and ordinary input restoring that baseline. Start a save of the baseline plus `1`, activate unchanged settings and request refresh, restore the original baseline while the PUT is pending, then settle the PUT and its recovery GET. Assert that recovery never paints the older submitted text over the newer baseline-return edit without an explicit choice. Confirm these activation cases fail before production changes.
- Include no-activation controls for the same editing paths. They must retain newer text and eventually persist it through the existing save lifecycle rather than introduce unnecessary conflicts. Cover both Keep mine and Use theirs in the activation case: before the choice the editor retains the newer text; Keep mine persists it, including an empty string; Use theirs alone authorizes replacement with the older remote text.
- Assert one outstanding PUT per destination throughout debounce, blur, pagehide, and repeated refresh attempts. Defer the recovery GET separately and assert that no newer automatic PUT starts before incoming state is classified. Check final modeled storage and editor text, not only mock call counts.

### 2. Track editing intent separately from baseline equality

- Introduce a monotonic local-edit revision in the pane. Advance it for committed ordinary input, paste/chunk edits, cuts, indentation changes, composition completion, and successful undo. Reuse the existing `noteEdited` path and explicitly cover `undoNote`, which currently bypasses it. Do not advance this revision for remote painting, status changes, refresh requests, or transport activation. Keep it distinct from `baselineRevision`, which invalidates reads for several non-edit reasons.
- Capture the submitted text and local-edit revision with each `NoteSaveAttempt`, alongside its transport and lifetime. Keep the existing destination key, synchronous slot acquisition, identity-checked release, and independent destination slots unchanged.
- Retain destination/lifetime-scoped provenance for an invalidated save through the ensuing reconciliation, separately from its outstanding-write slot. Record the submission revision even if there is no newer edit yet: a user may restore the baseline after the PUT settles but while the recovery GET is pending. Releasing a settled slot must not erase this reconciliation evidence.
- Establish or preserve that evidence when the save's view becomes obsolete, including when settlement is the first code path to observe the changed generation. Repeated same-destination activations and canceled/retried reads must not reset the original submission revision. Scope evidence so an old A completion cannot change B's draft state, baseline, or scheduling. Keep the state small and internal to the pane; no global editing journal or generic synchronization framework is needed.

### 3. Protect reconciliation and resolve provenance explicitly

- After a successful current-context GET and existing mount/revision/IME/write guards, compare the current local-edit revision with the relevant invalidated save's submission revision. Evaluate this at read application time, not only at PUT settlement, so edits before activation, during the PUT, and during the recovery GET are covered.
- Preserve the normal three-string classifier for ordinary synchronization. Before applying its `adopt` result, check whether protected newer editing exists. If it does and local text differs from fetched text, open the existing conflict dialog instead of painting the remote snapshot, even when local text equals `savedNote.current`. Keep read/retry and conflict guards ahead of automatic PUTs. Do not fake cleanliness by assigning the obsolete PUT's text to the current baseline.
- Permit safe convergence when a valid fetched snapshot equals current local text. Retire only the matching provenance when an authoritative read safely establishes the baseline without discarding the draft, a current save establishes its submitted baseline, or a current explicit conflict choice resolves that uncertainty. A conflict-producing read, failed/canceled/stale GET, obsolete PUT completion, or repeated settings activation must not clear unresolved protection merely because strings match the old baseline.
- Preserve existing `noop` behavior when the fetched server state still equals the retained baseline: ordinary differing drafts may continue through normal autosave, and a baseline-return draft already equal to the fetched server requires no redundant write. Do not force every failed-save recovery into a new conflict. Any retirement must be identity/revision-aware so an older read or attempt cannot erase newer provenance.
- Keep mine uses the fetched remote version as the explicitly accepted base and starts an authorized current-context save of the current draft. Use theirs adopts the remote text only through the existing explicit choice. Repeated events and another unchanged-settings activation while a conflict is open must continue protecting a baseline-return draft rather than clearing the dialog and subsequently treating the draft as clean.

### 4. Verify lifecycle boundaries and existing behavior

- Add focused timing cases for editing before unchanged activation, after activation while the PUT is pending, and after PUT settlement while its recovery GET is pending. Include a repeated activation that invalidates that GET; the old response must neither repaint the editor nor retire the newer recovery evidence.
- Exercise a recovery GET failure followed by retry without another event. Preserve the draft and write blocking until a successful current read classifies the incoming text. Exercise rejected obsolete PUTs with both unchanged server state and a modeled write that committed before its response failed; promise rejection alone must not certify that storage stayed unchanged.
- Cover equal local/remote convergence and a later clean remote update after resolution, proving protection does not become a permanent conflict latch. Retain append-only newer-draft regressions and ordinary focused clean-note adoption. Use existing A/B, A-to-B-to-A, local-directory generation, pagehide, IME, StrictMode, and stale-result tests as boundary controls; add a focused target-isolation assertion if the new provenance state needs one. A committed IME edit that returns to the baseline must receive the same protection as ordinary input.
- Run `npm test -- src/components/NotePane.test.tsx src/lib/resourceRefresh.test.ts src/lib/noteSync.test.ts` from `app/` while developing. Then run `npm test`, `npm run build`, and `git diff --check` in the relevant repositories. Keep all existing 446 frontend tests passing alongside the new cases, except for any explicitly documented expectation change required by the approved behavior. Do not weaken the existing one-outstanding-write assertions.
- Do not implement or claim to verify the separate unmount-during-post-save-recovery-await fix. Maintain existing lifetime checks in newly added work without broadening this task into lifecycle cleanup. If GUI access is unavailable, record the manual unchanged-settings/undo check as unavailable rather than claiming a desktop or device run.

### 5. Document, version, and record results

- Update the relevant app README/live-sync documentation to explain that newer undo or input remains protected even when it restores the old baseline, including empty text. Describe the conservative conflict choice and retain the limits of pane-local serialization and last-write-wins storage.
- During the implementation workflow, create a fresh branch matching `17-note-baseline-draft-protection` and apply the next patch version, currently `0.15.16` to `0.15.17`, consistently across npm package/lockfile, Cargo package/lockfile, and Tauri configuration. Do not upgrade dependencies as part of the version change.
- Record the changes, pre-fix failing cases, exact final test/build results, verification limits, and deferred warning in `tasks/17-note-baseline-draft-protection/4-implemented.md`. Commit app changes within the submodule before recording its pointer and report in the parent. No implementation, release metadata, or implementation-result file is changed during this planning stage.

## Acceptance Criteria

- Undo and ordinary input returning to either a nonempty or empty pre-save baseline survive unchanged-settings invalidation, PUT settlement, and recovery. A differing older snapshot cannot silently replace the newer draft, regardless of whether the edit occurs before activation, during the PUT, or during the GET.
- A current explicit Keep mine choice saves the newer draft, including empty text, and final storage matches it. Use theirs explicitly authorizes replacement. No-activation controls retain ordinary automatic-saving behavior, and clean-note remote adoption still works after provenance is resolved.
- Protection survives repeated same-destination activations, a canceled recovery read, failed GET/retry, and a rejected response whose write may have committed. It clears on a scoped authoritative resolution, not merely because the local text equals an obsolete baseline, and does not leak across destinations or lifetimes.
- There is never more than one pane-owned outstanding PUT to the same destination. Pending recovery and conflicts continue blocking automatic debounce, blur, and pagehide saves. Different destinations retain their existing independent ownership.
- The focused frontend suite, full frontend suite, production build, whitespace checks, and synchronized version checks pass, or exact blockers are recorded. No new server protocol, collaborative merging, dependency upgrades, unrelated warning fixes, or changes to `todo.md` are included.

## Risks And Decisions

- String equality describes content, not editing history. Reusing `noteDirty()` or `baselineRevision` as the sole provenance signal would repeat the bug or confuse remote/context activity with local edits. The local-edit revision must include undo, not only `onInput`.
- An edit counter captured only when a stale PUT completes misses editing during its recovery GET. Keep the submission revision available through reconciliation and evaluate the live revision when applying the read.
- Discarding all attempt metadata when releasing the write slot would leave no way to distinguish an intentionally restored baseline from a truly untouched editor. Outstanding ownership and unresolved reconciliation provenance have different lifetimes.
- Never use an obsolete write completion as an unconditional current saved baseline, and never infer from rejection that the server did not commit. The current GET and preserved draft intent determine whether adoption is safe.
- Prefer the existing conservative conflict over automatic overwrite when provenance makes an apparent clean adoption unsafe. This task does not require text merging, server revisions, new dialogs, or automatic replay of captured old text.
- Extra provenance must not permanently mark every later clean note as edited. Explicit retirement rules and a subsequent clean-update test are required. Destination/lifetime scoping must remain compatible with the existing A/B and local-generation ownership model.
