# Brooks-Lint Review

**Mode:** PR Review
**Scope:** Current branch `8-android-modal-dismissal` relative to `main`: parent `b7270e0..4296459` (app pointer and implementation report), app `20ee9e3..b03a4c0` (29 files). All diffs were inspected; behavioral analysis is sampled around event ownership, state-driven dismissal, queued presentations, and native test boundaries.
**Health Score:** 95/100
**Trend:** Stable at 95; the previous review assessed this task's plan rather than the implementation.

The implementation addresses the reproduced React dismissal failures across all modal families; real Android and desktop dialog behavior remains unverified.

## Findings

### Warning

**T5: Coverage Illusion — Native modal interaction has no successful runtime verification**

Symptom: The shared event logic in `app/src/components/dialogEvents.ts:4–12` and `useBackdropClose.ts:16–20` is protected by meaningful jsdom regressions, but native interaction still relies on the browser's modal top layer, backdrop targeting, focus restoration, and default cancel behavior. `app/src/test/setup.ts:6–10` only toggles `open` and synchronously dispatches close; the deferred helper adds controlled event delivery without implementing native hit testing or inertness. `4-implemented.md:36–39` records unavailable Android device access and failed desktop startup, so no native scenario succeeded. The report clearly discloses this gap and does not misrepresent the 343 tests as device evidence.

Source: *How Google Tests Software* — change coverage and risk-based suite composition; *The Art of Unit Testing* — testing boundary behavior at the appropriate integration level.

Consequence: The tests establish the covered React ownership and state transitions but cannot establish that an actual Android tap or Back gesture dismisses one native layer, that sibling overlays remain correctly ordered, or that focus returns to the surviving modal. Android packaging success also cannot establish those user-facing acceptance criteria. Browser-specific event ordering or gesture handling could still leave the original device symptom unresolved despite the passing suite.

Remedy: Complete the planned Android and desktop native checks using a reachable device/emulator and working browser/display environment. Record Android/WebView versions and test backdrop, Cancel/Done, native Back/Escape where supported, repeated reopen cycles, retained input, sibling label/removal handoffs, queued conflicts, and focus return. Include a real deferred-close/replacement sequence and inert-background behavior. Keep those acceptance criteria unverified until native results are available; additional mocked `open` assertions would not close this gap.

## Review Coverage

- Base detection: `main` is the direct base in each repository. The parent branch adds `4296459`; the app pointer adds `b03a4c0`. The server submodule has no branch change.
- Production files: Reviewed `dialogEvents.ts`, `usePickerDialog.ts`, `useBackdropClose.ts`, and all ten dialog components: `OptionsModal`, `SelectField`, `SortField`, `SettingsModal`, `EditTaskModal`, `LabelModal`, `RemoveLabelDialog`, `ConflictDialog`, `NoteConflictDialog`, and `OpenLinkDialog`.
- Test files: Reviewed changed AddForm, ConflictDialog, EditTaskModal, NotePane, OptionsModal, SelectField, SettingsModal, and SortField suites; new `ModalLifecycle.test.tsx`; and shared `src/test/dialog.ts` / `setup.ts`.
- Metadata and documentation: Reviewed `package.json`, `src-tauri/Cargo.toml`, `src-tauri/tauri.conf.json`, the parent app pointer, and `4-implemented.md`. Version values agree on `0.15.11`.
- Generated files: npm and Cargo lockfiles were excluded from decay analysis. Their diffs contain only the app version update, with no dependency changes.
- Configuration: Neither parent nor app root contains `.brooks-lint.yaml`; balanced defaults apply.
- R2: Event ownership is checked before state changes or `preventDefault()`. Child close/cancel cannot invoke ancestor dismissal handlers. Shared native click targeting remains isolated, with default label activation prevented. Settings/Edit preserve existing owner callbacks, avoiding a second semantic callback from prop-driven close. No concrete propagation defect found.
- R1: New helpers are small and named for their event responsibilities. The conflict finish guard is linear and local. The test scenarios are longer but represent one lifecycle story each; length alone does not justify a finding.
- R3: One shared ownership predicate and shared picker handlers keep event policy consistent. Repeated modal-specific callbacks encode distinct owners and semantics rather than duplicated domain decisions. No knowledge-duplication finding.
- R4: The fix retains native dialogs and existing state owners. The per-conflict handled reference addresses the observed queue lifecycle without a new modal manager, global key interception, portals, or timer workarounds. No speculative complexity finding.
- R5: New production dependencies flow only from UI components to a typed React event helper. No storage, server, native interface, dependency version, or layering change was introduced.
- R6: Sort remains live; label creation/removal handoffs retain their existing purpose; note conflict dismissal still uses NotePane's keep-mine path; server conflict dismissal writes nothing; link/removal cancellation performs no confirmation. No domain-contract distortion found.
- Queued presentation review: `ConflictDialog` now synchronizes on the active conflict object, allowing the next queued prompt to reopen after native dismissal. Its finish guard handles one choice/dismissal per current entry. Inactive presentations and currently reopened dialogs ignore inappropriate close callbacks. Tests cover queue advancement, old close delivery while a replacement is open, completion, and a choice waiting for its owner.
- Quick Test Check: State-bearing owner harnesses and real component compositions assert preserved inputs, surviving parent visibility, reopening, handoffs, and cancellation/confirmation effects. No mock-abuse or test-obscurity finding. Native cancellation is modeled as a non-bubbling, cancelable event rather than fabricated bubbling; controlled deferred delivery remains an integration approximation, as described in the warning.
- Verification: At the reviewed implementation commit, `npm test` passed 343 tests across 29 files, `npm run build` passed, and universal Android APK/AAB compilation and packaging passed for four architectures with NDK `29.0.13846066`. These are implementation-stage results observed in this session; they were not rerun during the documentation-only review. Branch `git diff --check` passed in both repositories during review.

## Summary

No concrete implementation defect was found; one warning remains for native runtime verification. The app diff exceeds 500 changed lines, a review-size/change-propagation signal, but most added code is behavioral coverage and the production edits form one cohesive all-modals change explicitly requested by the goal. Complete the native scenarios before treating Android dismissal and desktop focus/top-layer behavior as verified; no fixes were applied in this review.
