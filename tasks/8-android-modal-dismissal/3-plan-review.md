# Brooks-Lint Review

**Mode:** PR Review
**Scope:** `tasks/8-android-modal-dismissal/2-plan.md` at `1d6589a`, checked against the expanded `1-goal.md`, all ten dialog lifecycle patterns, owner callbacks, and existing test support.
**Health Score:** 95/100
**Trend:** Stable at 95; the previous PR Review assessed another task, so this is not a same-scope trend.

The plan covers all modal families, but queued dialogs need an explicit replacement lifecycle check as well as event isolation.

## Findings

### Warning

**R2: Change Propagation — A dismissed conflict can leave the next queued modal hidden**

Symptom: The original plan's lifecycle step (`2-plan.md:26`) requires avoiding consumption of another queued conflict, while its test steps (`32–37`) cover standalone and overlapping dialogs without an explicit queued replacement scenario. `app/src/components/ConflictDialog.tsx:21–28` synchronizes native visibility using only the boolean `open`. `app/src/App.tsx:61–74` advances directly from one non-null conflict to the next when dismissed. Native backdrop/cancel closes the current dialog, but the replacement keeps `open` true, so the visibility effect has no changed dependency to reopen it. Guarding event target identity does not address this same-element lifecycle transition.

Source: *A Philosophy of Software Design* — information hiding across the adapter/owner boundary; *Code Complete* — explicit state transitions and defensive error-path reasoning; *Software Engineering at Google* — observable behavior and implicit lifecycle contracts.

Consequence: The implementation can isolate every close event correctly yet leave the next queued prompt closed after one dismissal. A delayed close event associated with a previous presentation can also act on a replacement unless lifecycle ownership is checked. That violates usable remaining modals and makes all-modal completion depend on an untested interaction between native visibility and the owner's queue.

Remedy: Specify a stateful two-conflict regression: dismiss the first through backdrop and native cancel, require the next prompt to be open with its own content, and require a second action to dismiss it. Make native visibility synchronization observe the active presentation rather than only null/non-null state. Include confirmation and delayed programmatic-close cases so old lifecycle events cannot dismiss a replacement or invoke cancellation after a choice. Keep the fix local to dialog synchronization unless a failing owner-level test proves a broader queue change is necessary.

## Review Coverage

- R2: One lifecycle-boundary warning. The shared ownership check otherwise keeps the Android fix within the frontend boundary and addresses descendant close/cancel propagation.
- R1: The five-step plan has concrete files, commands, state rules, and test outcomes. Breadth reflects the explicit all-modals goal; no cognitive-overload finding.
- R3: One typed event helper and shared picker handlers avoid duplicated ownership policy while preserving modal-specific semantics. Existing coordinated version metadata follows the release convention.
- R4: Native dialogs, existing owners, and native top-layer behavior remain the default. A new modal manager, portals, global key listeners, and timers are not proposed without evidence. No speculative-complexity finding.
- R5: Dependency direction remains unchanged. React event details stay in UI adapters, with no storage, server, or Rust dependency introduced.
- R6: Label, task, settings, conflict, and link cancellation retain their existing meanings. The plan distinguishes cancellation from confirmation and does not force one domain callback onto all modals.
- Quick Test Check: Skipped because this is a documentation-only plan review. The proposed regression scenarios were assessed, including jsdom limitations, callback side effects, and native runtime requirements.
- Configuration: No `.brooks-lint.yaml` exists in the parent or app root; balanced defaults apply. Score reflects the original plan's one warning, now accepted and addressed.
- Verification limits: This review inspected source and test support. It did not reproduce Android behavior or run implementation tests. Native close-event timing, focus, top-layer ordering, and Android Back remain implementation-stage checks.

## Summary

One warning was accepted and addressed in `2-plan.md`: queued replacement dialogs need presentation-aware visibility and explicit lifecycle regressions. The revised plan also inventories local dialog test shims, including the conflict suite, so deferred-event checks use consistent support. No implementation code was changed.
