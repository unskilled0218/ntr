# plan

- [scope](#scope)
- [Implementation Plan](#implementation-plan)
  - [1. Reproduce overlapping saves](#1-reproduce-overlapping-saves)
  - [2. Separate destination ownership from view generations](#2-separate-destination-ownership-from-view-generations)
  - [3. Drain recovery before allowing another save](#3-drain-recovery-before-allowing-another-save)
  - [4. Verify and record results](#4-verify-and-record-results)
- [Acceptance Criteria](#acceptance-criteria)
- [Risks And Decisions](#risks-and-decisions)

## scope

Address only the critical finding in `tasks/15-server-live-update-recovery/5-code-review.md`: an unchanged-settings activation releases `NotePane`'s in-flight save guard and permits out-of-order writes to the same note destination. Primary implementation and test paths are `app/src/components/NotePane.tsx` and `app/src/components/NotePane.test.tsx`. Keep transport APIs, server persistence, SSE handling, and independent-editor last-write-wins behavior unchanged. Do not modify `todo.md`. The separate post-save unmount warning remains outside this task.

## Implementation Plan

### 1. Reproduce overlapping saves

- Extend the existing component tests using fake timers and `app/src/test/deferred.ts`. Model server storage with deferred PUTs that change stored text only when explicitly completed; make GETs return that stored text. Record captured transport contexts and outstanding writes without replacing the real activation/current-context helpers.
- Start on server A with `base`, type `1`, and hold the save of `base1`. Call `activateTransport()` and `onNoteChange()` to reproduce `App.onSettingsClose()` without changing the URL. Type `2`, trigger debounce, blur, pagehide, and repeated refreshes while the first PUT remains pending. Assert exactly one outstanding same-destination PUT and an intact `base12` draft. Confirm the regression fails against the current implementation.
- After completing the first PUT, defer the recovery GET and verify no newer PUT starts before reconciliation finishes. Finish recovery and either save the preserved draft automatically when classification permits or resolve the existing conflict with Keep mine. Complete the newer PUT, emit another note event, and verify both editor and modeled storage retain `base12`. A separate Use theirs check must demonstrate that discarding a draft requires an explicit choice.

### 2. Separate destination ownership from view generations

- Replace the resettable `savingNote` boolean with explicit outstanding-attempt ownership keyed by destination within the pane. Use the captured server URL for remote destinations and `localGeneration` for local storage destinations, with distinct remote/local keys. Transport generation and certificate policy invalidate view ownership but must not create a new write slot for the same URL.
- Store an attempt identity and its captured transport/lifetime with each owned write. Acquire the slot synchronously before invoking `putNote`; release only that exact attempt in settlement cleanup, regardless of success, failure, or transport invalidation. Do not clear outstanding slots in `syncContext` or effect cleanup; pending attempts release their own entries when they settle.
- Replace all boolean checks with checks for the current destination: normal and explicitly authorized saves, pagehide, reconciliation, and `ResourceRefresh.canRun`. Ensure pagehide writes also acquire and release ownership through the same small write-starting path, so repeated pagehide or another save trigger cannot overlap an outstanding PUT.
- Preserve separate slots for different destinations. A pending A write must not block reconciliation or an explicitly authorized write to B. Returning to A while its old attempt is pending must still see A's occupied slot. Do not introduce a generic queue, global transport redesign, or retries that replay captured old text.

### 3. Drain recovery before allowing another save

- Keep current `syncContext` behavior for read invalidation, timers, conflict reset, and transferred drafts, but retain outstanding write ownership. A same-destination refresh stays pending while its PUT is outstanding rather than reading a prematurely clean baseline or starting another save.
- Separate attempt release from UI ownership checks. A stale attempt must release its own destination slot, but must not set the current saved baseline, status, conflict state, or editor contents from its captured result. Current-generation saves retain their existing success/error behavior.
- When a settled attempt belongs to the active destination and pane lifetime, synchronize the latest transport context if necessary and resume pending recovery under that current context, even when the attempt's original generation is obsolete. Revalidate current ownership before new continuation work. Settlement for another destination or an obsolete lifetime must not drain or schedule current work.
- Require successful reconciliation after a same-destination context change before another automatic save. Keep incoming-read retry blocking, IME guards, transferred-draft authorization, and existing conflict classification. Do not declare the current draft saved merely because an obsolete request finished. If the old persisted snapshot differs from both the retained baseline and newer input, conservatively use the existing conflict dialog instead of silently adopting it or bypassing conflict handling.
- Add focused cases for rejected old PUTs, failed recovery GETs followed by retry, repeated unchanged activations, certificate-policy changes at the same URL, A-to-B-to-A transitions with deferred writes, and local-directory changes. Verify an old completion cannot release B's slot, alter B's UI, or leave recovery permanently blocked. Retain existing late-result and StrictMode tests; do not add a separate fix for the known post-save recovery-await unmount warning.

### 4. Verify and record results

- Run `npm test -- src/components/NotePane.test.tsx src/lib/resourceRefresh.test.ts src/lib/noteSync.test.ts` from `app/` while developing. Then run `npm test` and `npm run build` from `app/`. Record exact outcomes and any unavailable checks; this planning stage does not run or claim those results.
- If GUI access exists, hold or delay a save, close unchanged server settings, type more text, and verify newer text survives recovery. Otherwise record the GUI check as unavailable and rely on the deterministic transport-seam regression, not a claim of manual verification.
- During implementation, record changed files, regression results, remaining limitations, and the intentionally deferred warning in `tasks/16-note-save-ownership/4-implemented.md`. Follow the implementation workflow for versioning and commits, including the `app/` submodule commit before updating its parent pointer. This stage creates and commits only this plan.

## Acceptance Criteria

- At most one pane-owned PUT is outstanding per actual note destination across unchanged-settings activations, repeated refreshes, debounce, blur, and pagehide. Certificate-policy changes at the same URL do not bypass that guard.
- A same-destination activation cannot start a newer automatic PUT until the older attempt settles and current-context reconciliation succeeds. Recovery resumes without requiring another external event, including after a failed old attempt; failed GETs retain blocking and retry behavior.
- Newer local text remains intact throughout deferred PUT/GET completion. It reaches storage after automatic saving or an explicit Keep mine choice; it is replaced only through an explicit Use theirs choice when a conflict exists.
- Different server destinations and different local storage generations remain independently scoped. Returning to a destination with an outstanding attempt remains blocked. Obsolete completions release only their own slots and cannot update another context's UI or baseline.
- Existing note editing, conflict, IME, recovery, and stale-result tests pass alongside the new deterministic regression. The full frontend suite and production build pass, or exact blockers are recorded. No server protocol changes or unrelated warning fixes are included.

## Risks And Decisions

- Removing only `savingNote.current = false` would deadlock recovery because the old `finally` currently releases ownership only when its original generation is current. Ownership release and current-view continuation must be separate.
- Tracking only the latest attempt would lose A's ownership during A-to-B-to-A switches. Use a small per-destination collection with identity-checked deletion, retained only while attempts are outstanding.
- A settled request does not prove the server still contains that request's text; another client may have written meanwhile. Fresh reconciliation and the existing conflict rules remain authoritative. A conservative conflict after an obsolete successful save is acceptable; silent rebasing from that stale result is not.
- Destination identity follows the existing URL/local-generation distinction. Do not attempt URL-alias detection or infer that different URLs share storage. This fix covers saves owned by the mounted pane, not serialization across separate clients or unrelated API writers.
- Do not add a timeout that frees a slot while its PUT may still reach storage. An indefinitely pending request keeps that destination blocked; request cancellation and server-side ordering guarantees are separate work.
