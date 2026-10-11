# Brooks-Lint Review

**Mode:** PR Review
**Scope:** All changes on `10-picker-cancel-project-handoff` relative to `main`: parent `94a82d4..8637cc1` (app pointer and implementation report), app `0d57dba..a092b39` (14 files covering picker components, regression support/tests, and release metadata).
**Health Score:** 95/100
**Trend:** 100 → 95 (−5); the previous review assessed this task's plan rather than its runtime verification evidence.

The code establishes picker closure before replacement callbacks, but the reported Cancel and project-modal interaction still needs native browser/device verification.

## Findings

### Warning

**T5: Coverage Illusion — Modeled label activation cannot verify the reported native interaction**

Symptom: `app/src/test/dialog.ts:16–20` manually clicks the captured enclosing label after React removes an unprevented action target. That is a clearly documented hypothesis model, not a browser-generated default action. The replacement observer at lines 24–33 checks `open` flags through a jsdom `showModal` shim, without native top-layer hit testing. `4-implemented.md:26–29` records no successful browser/device scenario: GTK aborted before page execution and ADB was unreachable. Actual label reactivation, pointer/keyboard Cancel, native focus, and creation-modal interactivity remain unverified.

Source: *How Google Tests Software* — risk-based integration coverage and change coverage; *The Art of Unit Testing* — completeness of tests at external behavior boundaries.

Consequence: Passing the modeled cases shows that click-default prevention blocks the deliberately replayed activation path, but cannot establish that this is the cause on the affected platform or that the user's Cancel/hidden-creation symptom is resolved. The independently tested closure-at-callback contract is valuable, yet an additional browser event or focus/top-layer path could still leave the reported interaction broken.

Remedy: Reproduce the original sequence on the affected device/browser, recording versions, actual click/default/trigger events, native close/open order, and modal state. Verify mouse/touch Cancel and keyboard activation, repeated reopening, compact/noncompact AddForm and Edit task project handoffs, preserved input, creation/cancellation, topmost hit testing, and focus. Compare the observed sequence with the modeled helper and adjust its assumptions if needed. Keep the native acceptance criteria open until this evidence exists; do not promote manually replayed label clicks or `open` flags into native proof.

## Review Coverage

- Base detection: `main` is the direct base in each repository. The parent adds `8637cc1`; its app pointer adds `a092b39`. The server submodule has no branch change.
- Production files reviewed: `usePickerDialog.ts`, `SelectField.tsx`, `PickerList.tsx`, `OptionsModal.tsx`, and `SortField.tsx`.
- Tests/support reviewed: SelectField, AddForm, and EditTaskModal regression additions and `src/test/dialog.ts`. Existing event-ownership and deferred-close behavior were checked as supporting context.
- Metadata/documentation reviewed: npm/Cargo/Tauri package metadata, app pointer, and `4-implemented.md`. Version values agree on `0.15.13`. Generated npm/Cargo lockfiles were excluded from decay analysis; their diffs change only the app version.
- Configuration: Neither parent nor app root contains `.brooks-lint.yaml`; balanced defaults apply.
- R2: `closePicker()` invokes native close before returning, and SelectField invokes selection/removal callbacks afterward. Cancel/Done and choice/removal click defaults are prevented before their actions. Backdrop uses the shared close operation; owned native close/cancel handling remains intact. No concrete change-propagation defect found.
- R1: The new close operation and click handlers are short and explicit. Longer form tests represent a coherent pending-input/replacement lifecycle with named fields and observable outcomes. No cognitive-overload finding based on length alone.
- R3: Picker closure is centralized in the existing hook, and row click policy stays in PickerList without passing DOM events through value callbacks. No duplicated modal manager or domain policy.
- R4: Native opening remains effect-driven for mounted contents; explicit closure serves an existing replacement-order requirement. No timers, forced rendering, z-index workarounds, portals, or speculative framework were introduced.
- R5: Changes stay in the current frontend boundary. No new dependency, backend/native interface, or layering change was added. Coordinated version files follow the existing release convention.
- R6: Cancel does not select/remove/create a label or submit/save a task. Confirmation retains the existing staging flow; Sort choices remain live. Regression additions check pending description/due/priority/project values and surviving Options/Edit state.
- Quick Test Check: Callback-entry `open === false` regressions protect a real ordering boundary and failed before the fix. Stateful forms and deferred events cover cancellation/reopening, old event delivery, staged creation, and absent Add/Save side effects. The helper's `showModal` spy observes native visibility state rather than merely asserting a call. No separate mock-abuse or test-obscurity finding; native coverage limits are captured in T5.
- Verification: At the reviewed implementation commit, the planned focused command passed 102 tests, `npm test` passed 360 tests across 29 files, and `npm run build` passed TypeScript/Vite checks. These implementation-stage results were observed in this session; they were not rerun for this documentation-only review. Branch `git diff --check` passed in both repositories during review.

## Summary

No concrete implementation defect was found; one warning remains for unverified native activation and modal interaction. The report and test helper correctly distinguish modeled behavior from device evidence, and the native closure-before-callback improvement has meaningful regression coverage. Complete the browser/device scenarios before treating the reported symptom as verified; no fixes were applied during review.
